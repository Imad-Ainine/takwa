-- ─────────────────────────────────────────────────────────────
-- Security & abuse-prevention audit (2026-09-15): community_adhkar
-- and community_duas accept unbounded text and have no rate limit.
-- Since 20260912012000_default_approve_community_shares.sql, every
-- share is auto-approved and visible app-wide immediately (that
-- migration made this the correct behavior on purpose — there is
-- still no moderation UI anywhere in this app to review/un-approve
-- content, so flipping `approved` back to requiring review would
-- silently make every new share invisible forever again, the exact
-- bug that migration fixed). This migration does NOT touch
-- `approved` — it only closes the concretely exploitable gaps:
-- a user scripting unbounded-size or rapid-fire inserts.
--
-- 1) CHECK constraints cap each text field at a generous but finite
--    length (matches what the UI reasonably expects to display).
-- 2) A BEFORE INSERT trigger caps each user to 10 shares per table
--    per rolling hour. Both checks run server-side (not just in the
--    Flutter client), so they hold regardless of insert path.
-- ─────────────────────────────────────────────────────────────

alter table public.community_adhkar
  add constraint community_adhkar_text_ar_length check (char_length(text_ar) between 1 and 2000),
  add constraint community_adhkar_category_hint_length check (category_hint is null or char_length(category_hint) <= 100);

alter table public.community_duas
  add constraint community_duas_title_ar_length check (char_length(title_ar) between 1 and 200),
  add constraint community_duas_text_ar_length check (char_length(text_ar) between 1 and 2000),
  add constraint community_duas_occasion_length check (occasion is null or char_length(occasion) <= 200),
  add constraint community_duas_source_length check (source is null or char_length(source) <= 300),
  add constraint community_duas_emoji_length check (emoji is null or char_length(emoji) <= 16);

create or replace function public.enforce_community_share_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count int;
  share_limit constant int := 10;
  window_interval constant interval := interval '1 hour';
begin
  execute format(
    'select count(*) from %I where shared_by = $1 and created_at > now() - $2',
    TG_TABLE_NAME
  )
  into recent_count
  using new.shared_by, window_interval;

  if recent_count >= share_limit then
    raise exception 'Rate limit exceeded: max % shares per % per user', share_limit, window_interval
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists community_adhkar_rate_limit on public.community_adhkar;
create trigger community_adhkar_rate_limit
  before insert on public.community_adhkar
  for each row execute function public.enforce_community_share_rate_limit();

drop trigger if exists community_duas_rate_limit on public.community_duas;
create trigger community_duas_rate_limit
  before insert on public.community_duas
  for each row execute function public.enforce_community_share_rate_limit();
