-- ─────────────────────────────────────────────────────────────
-- Fix for get_circle_leaderboard RPC:
-- 1) Disambiguate user_id column references (was causing Postgres 42702).
-- 2) Return explicit sharing boolean flags (share_streak, share_points,
--    share_checklist_done, share_quran_pages) from circle_members so
--    the client doesn't have to infer them from null values.
-- ─────────────────────────────────────────────────────────────

drop function if exists "public".get_circle_leaderboard(uuid);

create or replace function "public".get_circle_leaderboard(p_circle_id uuid)
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
set search_path = "public"
as $$
begin
  if not exists (
    select 1 from "public".circle_members cm
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
        select 1 from "public".daily_records d
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
  from "public".circle_members m
  left join "public".profiles p on p.id = m.user_id
  where m.circle_id = p_circle_id;
end;
$$;

revoke all on function "public".get_circle_leaderboard(uuid) from public, anon;
grant execute on function "public".get_circle_leaderboard(uuid) to authenticated;
