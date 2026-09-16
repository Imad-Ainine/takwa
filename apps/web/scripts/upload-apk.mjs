#!/usr/bin/env node
/**
 * upload-apk.mjs
 * ──────────────
 * Uploads the Flutter release APK to Supabase Storage and prints the
 * public download URL.  Run this once after every `flutter build apk`.
 *
 * Usage:
 *   node scripts/upload-apk.mjs
 *
 * Prerequisites:
 *   - Set SUPABASE_SERVICE_ROLE_KEY in your shell (find it in Supabase → Settings → API).
 *   - SUPABASE_URL is already in .env — this script reads it from there.
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://fmmgiykwebwruhxeztvs.supabase.co';
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET = 'apk-releases';
const APK_VERSION = process.env.NEXT_PUBLIC_APK_VERSION || '1.0.0';
const OBJECT_PATH = `takwa-v${APK_VERSION}-arm64.apk`;

const APK_PATH = resolve(
  __dirname,
  '../../../mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
);

if (!SERVICE_ROLE_KEY) {
  console.error(
    '\n❌  SUPABASE_SERVICE_ROLE_KEY is not set.\n' +
    '   Find it in: Supabase Dashboard → Settings → API → service_role key\n' +
    '   Then run:  $env:SUPABASE_SERVICE_ROLE_KEY="<your-key>" ; node scripts/upload-apk.mjs\n'
  );
  process.exit(1);
}

if (!existsSync(APK_PATH)) {
  console.error(`\n❌  APK not found at:\n   ${APK_PATH}`);
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

console.log(`\n📦  Reading APK…`);
const fileBuffer = readFileSync(APK_PATH);
const sizeMB = (fileBuffer.byteLength / 1024 / 1024).toFixed(1);
console.log(`📏  Size: ${sizeMB} MB`);

const { data: buckets } = await supabase.storage.listBuckets();
const bucketExists = buckets?.some((b) => b.name === BUCKET);
if (!bucketExists) {
  console.log(`🪣  Creating public bucket "${BUCKET}"…`);
  const { error } = await supabase.storage.createBucket(BUCKET, { public: true });
  if (error) { console.error('❌  Bucket creation failed:', error.message); process.exit(1); }
}

console.log(`⬆️  Uploading as "${OBJECT_PATH}"…`);
const { error: uploadError } = await supabase.storage
  .from(BUCKET)
  .upload(OBJECT_PATH, fileBuffer, {
    contentType: 'application/vnd.android.package-archive',
    upsert: true,
  });

if (uploadError) { console.error('❌  Upload failed:', uploadError.message); process.exit(1); }

const { data: urlData } = supabase.storage.from(BUCKET).getPublicUrl(OBJECT_PATH);
const publicUrl = urlData.publicUrl;

console.log('\n✅  Upload successful!\n');
console.log('──────────────────────────────────────────────────────');
console.log(`🔗  Public URL:\n   ${publicUrl}`);
console.log('\n📝  Add to your .env (and Vercel env vars):');
console.log(`   NEXT_PUBLIC_APK_URL=${publicUrl}`);
console.log(`   NEXT_PUBLIC_APK_SIZE=${sizeMB} MB`);
console.log('──────────────────────────────────────────────────────\n');
