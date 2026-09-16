-- ─────────────────────────────────────────────────────────────
-- Repoint every book's pdf_url at the book-pdfs Storage bucket
-- (see 20260906194628_create_book_pdfs_bucket.sql) instead of
-- islamhouse.com. All 9 files were verified byte-identical between
-- the islamhouse.com download and the uploaded Storage object
-- before this migration was written.
-- ─────────────────────────────────────────────────────────────

update public.books
set pdf_url = case id
  when 'ar_alitkan_fi_aloum_alquran' then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/ar_alitkan_fi_aloum_alquran.pdf'
  when 'arboun_nawawi'               then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/arboun_nawawi.pdf'
  when 'daa_dawaa'                   then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/daa_dawaa.pdf'
  when 'fiqh_as_sunnah'              then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/fiqh_as_sunnah.pdf'
  when 'kitab_atawheed'              then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/kitab_atawheed.pdf'
  when 'riyad_salihin'               then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/riyad_salihin.pdf'
  when 'sahih_bukhari'               then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/sahih_bukhari.pdf'
  when 'tafsir_ibn_kathir'           then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/tafsir_ibn_kathir.pdf'
  when 'zad_al_maad_4'               then 'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/zad_al_maad_4.pdf'
  else pdf_url
end
where id in (
  'ar_alitkan_fi_aloum_alquran', 'arboun_nawawi', 'daa_dawaa', 'fiqh_as_sunnah',
  'kitab_atawheed', 'riyad_salihin', 'sahih_bukhari', 'tafsir_ibn_kathir', 'zad_al_maad_4'
);
