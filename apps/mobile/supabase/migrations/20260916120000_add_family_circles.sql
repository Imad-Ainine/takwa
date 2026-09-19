-- ─────────────────────────────────────────────────────────────
-- Family/Community Accountability Circles — see
-- docs/specs/family-community-features.md.
--
-- Privacy is the point of this schema, not an afterthought: a circle
-- member only ever sees another member's *opted-in, aggregate* signals
-- (streak/points/quran pages/"did today's checklist"), never raw
-- daily_records/prohibitions_log rows. That's enforced by never letting
-- the client read profiles/daily_records for another user directly —
-- RLS on those tables stays owner-only exactly as it is today. Instead
-- every cross-user read goes through get_circle_leaderboard(), a single
-- SECURITY DEFINER function that returns NULL for any signal the member
-- hasn't opted into, computed server-side.
--
-- Same reasoning drives every mutation here: circles/circle_members have
-- no client-facing INSERT/UPDATE policy at all. Joining a circle must
-- prove knowledge of its invite code, and updating your own sharing
-- toggles must not be able to "move" your membership row to a different
-- circle_id (the same class of bug 20260906190603_fix_community_content_
-- policies.sql fixed for community_adhkar/community_duas' likes column).
-- So both go through narrow SECURITY DEFINER RPCs instead of a direct
-- table policy, following that migration's precedent.
-- ─────────────────────────────────────────────────────────────

-- ── Tables ──────────────────────────────────────────────────────

create table public.circles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

create table public.circle_members (
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  -- All default false: sharing is opt-in, never on by joining alone.
  share_streak boolean not null default false,
  share_points boolean not null default false,
  share_checklist_done boolean not null default false,
  share_quran_pages boolean not null default false,
  primary key (circle_id, user_id)
);

create index idx_circle_members_user on public.circle_members(user_id);

create table public.circle_reactions (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  from_user_id uuid not null references auth.users(id) on delete cascade,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  -- Fixed, pre-approved phrase set — no free text, so there is nothing
  -- here that ever needs moderation (see the spec's Non-goals).
  phrase_key text not null check (
    phrase_key in ('dua_for_you', 'keep_going', 'proud_of_you', 'you_can_do_it', 'mashallah')
  ),
  created_at timestamptz not null default now()
);

create index idx_circle_reactions_to_user on public.circle_reactions(to_user_id, created_at desc);
create index idx_circle_reactions_circle on public.circle_reactions(circle_id, created_at desc);

alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.circle_reactions enable row level security;

-- ── Membership check, used inside RLS policies below ─────────────
-- SECURITY DEFINER so it bypasses RLS on its own lookup — the standard
-- way to avoid a self-referential-RLS recursion on circle_members.
create or replace function public.is_circle_member(p_circle_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists(
    select 1 from public.circle_members
    where circle_id = p_circle_id and user_id = auth.uid()
  );
$$;

revoke all on function public.is_circle_member(uuid) from public, anon;
grant execute on function public.is_circle_member(uuid) to authenticated;

-- ── RLS: read-only for clients; every mutation is a narrow RPC below ──

create policy "Members and owner can view their circles" on public.circles
  for select using (public.is_circle_member(id) or owner_id = auth.uid());

create policy "Owner can delete their circle" on public.circles
  for delete using (owner_id = auth.uid());

create policy "Members can view their circle's membership rows" on public.circle_members
  for select using (public.is_circle_member(circle_id));

create policy "A member can remove themselves from a circle" on public.circle_members
  for delete using (user_id = auth.uid());

create policy "Members can view reactions in their circles" on public.circle_reactions
  for select using (public.is_circle_member(circle_id));

-- ── RPC: create_circle ────────────────────────────────────────
create or replace function public.create_circle(p_name text)
returns public.circles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_circle public.circles;
begin
  if char_length(trim(p_name)) < 1 or char_length(p_name) > 60 then
    raise exception 'Circle name must be between 1 and 60 characters' using errcode = 'P0001';
  end if;

  loop
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    begin
      insert into public.circles (owner_id, name, invite_code)
      values (auth.uid(), trim(p_name), v_code)
      returning * into v_circle;
      exit;
    exception when unique_violation then
      -- Invite code collision (astronomically unlikely at 8 chars) — retry.
    end;
  end loop;

  insert into public.circle_members (circle_id, user_id)
  values (v_circle.id, auth.uid());

  return v_circle;
end;
$$;

revoke all on function public.create_circle(text) from public, anon;
grant execute on function public.create_circle(text) to authenticated;

-- ── RPC: join_circle_by_code ──────────────────────────────────
create or replace function public.join_circle_by_code(p_invite_code text)
returns public.circles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle public.circles;
begin
  select * into v_circle from public.circles where invite_code = upper(trim(p_invite_code));
  if not found then
    raise exception 'Invalid invite code' using errcode = 'P0002';
  end if;

  insert into public.circle_members (circle_id, user_id)
  values (v_circle.id, auth.uid())
  on conflict (circle_id, user_id) do nothing;

  return v_circle;
end;
$$;

revoke all on function public.join_circle_by_code(text) from public, anon;
grant execute on function public.join_circle_by_code(text) to authenticated;

-- ── RPC: update_circle_sharing ────────────────────────────────
-- Deliberately an RPC, not a client UPDATE policy: a raw
-- `using/with check (user_id = auth.uid())` policy can't stop a member
-- from also rewriting their row's circle_id in the same UPDATE, which
-- would let them "move" their membership into a circle they were never
-- invited to — the same column-tampering bug class fixed in
-- 20260906190603_fix_community_content_policies.sql. Fixing every
-- other column server-side sidesteps that entirely.
create or replace function public.update_circle_sharing(
  p_circle_id uuid,
  p_share_streak boolean,
  p_share_points boolean,
  p_share_checklist_done boolean,
  p_share_quran_pages boolean
) returns void
language sql
security definer
set search_path = public
as $$
  update public.circle_members
  set share_streak = p_share_streak,
      share_points = p_share_points,
      share_checklist_done = p_share_checklist_done,
      share_quran_pages = p_share_quran_pages
  where circle_id = p_circle_id and user_id = auth.uid();
$$;

revoke all on function public.update_circle_sharing(uuid, boolean, boolean, boolean, boolean) from public, anon;
grant execute on function public.update_circle_sharing(uuid, boolean, boolean, boolean, boolean) to authenticated;

-- ── RPC: send_circle_reaction ─────────────────────────────────
create or replace function public.send_circle_reaction(
  p_circle_id uuid,
  p_to_user_id uuid,
  p_phrase_key text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count int;
  reaction_limit constant int := 30;
  window_interval constant interval := interval '1 hour';
begin
  if not exists (
    select 1 from public.circle_members where circle_id = p_circle_id and user_id = auth.uid()
  ) then
    raise exception 'Not a member of this circle' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.circle_members where circle_id = p_circle_id and user_id = p_to_user_id
  ) then
    raise exception 'Recipient is not a member of this circle' using errcode = 'P0001';
  end if;
  if p_phrase_key not in ('dua_for_you', 'keep_going', 'proud_of_you', 'you_can_do_it', 'mashallah') then
    raise exception 'Invalid phrase' using errcode = 'P0001';
  end if;

  select count(*) into recent_count
  from public.circle_reactions
  where from_user_id = auth.uid() and created_at > now() - window_interval;
  if recent_count >= reaction_limit then
    raise exception 'Rate limit exceeded: max % reactions per % per user', reaction_limit, window_interval
      using errcode = 'P0001';
  end if;

  insert into public.circle_reactions (circle_id, from_user_id, to_user_id, phrase_key)
  values (p_circle_id, auth.uid(), p_to_user_id, p_phrase_key);
end;
$$;

revoke all on function public.send_circle_reaction(uuid, uuid, text) from public, anon;
grant execute on function public.send_circle_reaction(uuid, uuid, text) to authenticated;

-- ── RPC: get_circle_leaderboard ───────────────────────────────
-- The one deliberate, narrow exception to "RLS on profiles/daily_records
-- stays owner-only": this reads other members' profiles/daily_records,
-- but returns NULL for any field that member hasn't opted into sharing
-- in *this* circle, and raises if the caller isn't themselves a member.
create or replace function public.get_circle_leaderboard(p_circle_id uuid)
returns table (
  user_id uuid,
  username text,
  avatar_emoji text,
  current_streak int,
  total_points int,
  quran_pages int,
  checklist_done_today boolean,
  joined_at timestamptz,
  share_streak boolean,
  share_points boolean,
  share_checklist_done boolean,
  share_quran_pages boolean
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.circle_members cm
    where cm.circle_id = p_circle_id and cm.user_id = auth.uid()
  ) then
    raise exception 'Not a member of this circle' using errcode = 'P0001';
  end if;

  return query
  select
    m.user_id,
    p.username,
    p.avatar_emoji,
    case when m.share_streak then coalesce(p.current_streak, 0) else null end,
    case when m.share_points then coalesce(p.total_points, 0) else null end,
    case when m.share_quran_pages then coalesce(p.quran_pages, 0) else null end,
    case when m.share_checklist_done then
      exists(
        select 1 from public.daily_records d
        where d.user_id = m.user_id
          and d.date = current_date
          and d.net_points > 0
      )
    else null end,
    m.joined_at,
    m.share_streak,
    m.share_points,
    m.share_checklist_done,
    m.share_quran_pages
  from public.circle_members m
  left join public.profiles p on p.id = m.user_id
  where m.circle_id = p_circle_id;
end;
$$;

revoke all on function public.get_circle_leaderboard(uuid) from public, anon;
grant execute on function public.get_circle_leaderboard(uuid) to authenticated;

-- ── RPC: my_circles ───────────────────────────────────────────
-- Convenience wrapper so the client doesn't need a separate SELECT
-- against circle_members joined to circles just to list "my circles".
create or replace function public.my_circles()
returns table (
  id uuid,
  name text,
  invite_code text,
  owner_id uuid,
  member_count bigint,
  joined_at timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select
    c.id,
    c.name,
    c.invite_code,
    c.owner_id,
    (select count(*) from public.circle_members cm2 where cm2.circle_id = c.id) as member_count,
    cm.joined_at
  from public.circles c
  join public.circle_members cm on cm.circle_id = c.id and cm.user_id = auth.uid()
  order by cm.joined_at desc;
$$;

revoke all on function public.my_circles() from public, anon;
grant execute on function public.my_circles() to authenticated;
