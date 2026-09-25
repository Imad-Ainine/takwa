-- ─────────────────────────────────────────────────────────────
-- Fix for the circle owner-control RPCs (20260917000000_circle_owner_controls.sql).
--
-- delete_circle and remove_circle_member have never worked: both declare a
-- parameter named `circle_id` while every statement in their body also names a
-- `circle_id` *column*, so PL/pgSQL cannot resolve the bare reference and
-- Postgres aborts with 42702 "column reference circle_id is ambiguous". The app
-- surfaces that as the generic circleErrorGeneric snackbar.
--
-- This is the same bug class as get_circle_leaderboard, fixed the same way in
-- 20260919203000_fix_get_circle_leaderboard.sql: p_-prefixed parameters, an
-- explicit search_path, and narrow execute grants.
--
-- rename_circle is *not* affected (circles has no circle_id column, so nothing
-- is ambiguous) and does work today. It is recreated here with its signature
-- unchanged purely to add the missing search_path and grants, and to close the
-- same ownership hole the other two share: `(SELECT owner_id ...) <> auth.uid()`
-- is NULL, not TRUE, for a circle that does not exist.
-- ─────────────────────────────────────────────────────────────

drop function if exists "public".delete_circle(uuid);
drop function if exists "public".remove_circle_member(uuid, uuid);

-- rename_circle(circle_id uuid, new_name text)
-- Signature is deliberately unchanged — the released client calls it by these
-- parameter names.
create or replace function "public".rename_circle(circle_id uuid, new_name text)
returns void
language plpgsql
security definer
set search_path = "public"
as $$
begin
  if not exists (
    select 1 from "public".circles c
    where c.id = circle_id and c.owner_id = auth.uid()
  ) then
    raise exception 'not_owner';
  end if;
  if trim(new_name) = '' or char_length(new_name) > 50 then
    raise exception 'invalid_name';
  end if;
  update "public".circles set name = new_name where id = circle_id;
end;
$$;

-- delete_circle(p_circle_id uuid)
-- circle_members rows go with it via their `on delete cascade` FK.
create or replace function "public".delete_circle(p_circle_id uuid)
returns void
language plpgsql
security definer
set search_path = "public"
as $$
begin
  if not exists (
    select 1 from "public".circles c
    where c.id = p_circle_id and c.owner_id = auth.uid()
  ) then
    raise exception 'not_owner';
  end if;
  delete from "public".circles where id = p_circle_id;
end;
$$;

-- remove_circle_member(p_circle_id uuid, p_member_user_id uuid)
-- The owner cannot remove themselves; they leave through leaveCircle instead.
create or replace function "public".remove_circle_member(
  p_circle_id uuid,
  p_member_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = "public"
as $$
begin
  if not exists (
    select 1 from "public".circles c
    where c.id = p_circle_id and c.owner_id = auth.uid()
  ) then
    raise exception 'not_owner';
  end if;
  if p_member_user_id = auth.uid() then
    raise exception 'cannot_remove_self';
  end if;
  delete from "public".circle_members
  where circle_id = p_circle_id and user_id = p_member_user_id;
end;
$$;

revoke all on function "public".rename_circle(uuid, text) from public, anon;
revoke all on function "public".delete_circle(uuid) from public, anon;
revoke all on function "public".remove_circle_member(uuid, uuid) from public, anon;

grant execute on function "public".rename_circle(uuid, text) to authenticated;
grant execute on function "public".delete_circle(uuid) to authenticated;
grant execute on function "public".remove_circle_member(uuid, uuid) to authenticated;
