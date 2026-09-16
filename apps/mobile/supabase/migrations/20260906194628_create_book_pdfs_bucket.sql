-- ─────────────────────────────────────────────────────────────
-- Book PDFs move from runtime-scraping islamhouse.com (with a
-- spoofed desktop User-Agent to bypass its SSL/referer checks —
-- see the Security & Privacy audit, 2026-09-06) to Supabase
-- Storage, which the app already runs as its sync backend.
--
-- Public, read-only bucket: these are freely-distributed classical
-- Islamic texts (the same PDFs previously fetched from
-- islamhouse.com), not user content, so — same shape as the
-- `books`/`adhkar` reference tables — anyone can read, nobody
-- writes from the client. Uploads happen out-of-band (this
-- migration's own session, or the dashboard), the same way the
-- `books` table's rows are managed today.
-- ─────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'book-pdfs',
  'book-pdfs',
  true,
  52428800, -- 50 MB per file — generous headroom over any of these texts
  array['application/pdf']
)
on conflict (id) do nothing;

create policy "Anyone can read book PDFs"
  on storage.objects
  for select
  using (bucket_id = 'book-pdfs');
