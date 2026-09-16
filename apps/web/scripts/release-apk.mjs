#!/usr/bin/env node
/**
 * release-apk.mjs
 * ───────────────
 * Production-grade release pipeline script for the Takwa Android APK:
 * 1. Validates presence and size of the Flutter build output APK.
 * 2. Computes both SHA-256 and SHA-1 cryptographic hashes.
 * 3. Uploads the lightweight release manifest (manifest.json) to Supabase Storage (bypassing the 50MB file limit).
 * 4. Outputs ready-to-paste environment variables and optionally writes them to .env and .env.local.
 * 5. Provides instructions or commands for creating the GitHub Release to host the APK binary.
 *
 * Usage:
 *   node scripts/release-apk.mjs [--write-env]
 *
 * Environment variables:
 *   SUPABASE_SERVICE_ROLE_KEY - Supabase Service Role Key (Required)
 *   SUPABASE_URL             - Supabase project URL (Optional, defaults to project URL)
 *   NEXT_PUBLIC_APK_VERSION  - Semver string (Optional, defaults to 1.0.0)
 *   SUPABASE_APK_BUCKET      - Storage bucket name (Optional, defaults to "apk-releases")
 *   GITHUB_REPO              - GitHub repo "owner/repo" (Optional, defaults to "Imad-Ainine/Takkwa")
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { createHash } from 'crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Auto-load .env and .env.local if present
function loadEnvFile(filepath) {
  if (!existsSync(filepath)) return;
  const content = readFileSync(filepath, 'utf8');
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    const val = trimmed.slice(eqIdx + 1).trim().replace(/^["']|["']$/g, '');
    if (!process.env[key]) {
      process.env[key] = val;
    }
  }
}

loadEnvFile(resolve(__dirname, '../.env.local'));
loadEnvFile(resolve(__dirname, '../.env'));

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://fmmgiykwebwruhxeztvs.supabase.co';
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET = process.env.SUPABASE_APK_BUCKET || 'apk-releases';
const APK_VERSION = process.env.NEXT_PUBLIC_APK_VERSION || '1.0.0';
const GITHUB_REPO = process.env.GITHUB_REPO || 'Imad-Ainine/Takwa';
const GITHUB_DOWNLOAD_URL = `https://github.com/${GITHUB_REPO}/releases/download/v${APK_VERSION}/takwa-v${APK_VERSION}.apk`;

// Target location of Flutter APK release build (inside monorepo apps/mobile)
const APK_PATH = resolve(
  __dirname,
  '../../mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
);

// Fallback path if universal release APK is built
const FALLBACK_APK_PATH = resolve(
  __dirname,
  '../../mobile/build/app/outputs/flutter-apk/app-release.apk'
);

const targetApk = existsSync(APK_PATH) ? APK_PATH : (existsSync(FALLBACK_APK_PATH) ? FALLBACK_APK_PATH : null);

console.log('🕌 ──────────────────────────────────────────');
console.log('   TAKWA MOBILE APP — APK RELEASE PIPELINE   ');
console.log('────────────────────────────────────────────\n');

if (!SERVICE_ROLE_KEY) {
  console.error(
    '❌  SUPABASE_SERVICE_ROLE_KEY is required.\n' +
    '   Please set it in your environment or CLI session:\n' +
    '   $env:SUPABASE_SERVICE_ROLE_KEY="<your-key>" ; node scripts/release-apk.mjs\n'
  );
  process.exit(1);
}

if (!targetApk) {
  console.error(
    `❌  No release APK found.\n` +
    `   Checked paths:\n` +
    `     - ${APK_PATH}\n` +
    `     - ${FALLBACK_APK_PATH}\n\n` +
    `   Please build the APK first with:\n` +
    `     cd apps/mobile && flutter build apk --split-per-abi --release\n`
  );
  process.exit(1);
}

console.log(`📁  Target APK: ${targetApk}`);
const fileBuffer = readFileSync(targetApk);
const sizeBytes = fileBuffer.byteLength;
const sizeMB = (sizeBytes / (1024 * 1024)).toFixed(2);
console.log(`📏  Size: ${sizeMB} MB (${sizeBytes.toLocaleString()} bytes)`);

// Checksum calculation
console.log('🔒  Computing cryptographic hashes…');
const sha256 = createHash('sha256').update(fileBuffer).digest('hex');
const sha1 = createHash('sha1').update(fileBuffer).digest('hex');
console.log(`    SHA-256: ${sha256}`);
console.log(`    SHA-1:   ${sha1}`);

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

console.log(`\n🪣  Checking Supabase Storage bucket "${BUCKET}"…`);
const { data: buckets, error: bucketListErr } = await supabase.storage.listBuckets();
if (bucketListErr) {
  console.error('❌  Failed to list buckets:', bucketListErr.message);
  process.exit(1);
}

const bucketExists = buckets?.some((b) => b.name === BUCKET);
if (!bucketExists) {
  console.log(`    Creating public bucket "${BUCKET}"…`);
  const { error: createErr } = await supabase.storage.createBucket(BUCKET, { public: true });
  if (createErr) {
    console.error('❌  Failed to create bucket:', createErr.message);
    process.exit(1);
  }
}

// Build manifest payload
const manifest = {
  version: APK_VERSION,
  apkUrl: GITHUB_DOWNLOAD_URL,
  size: `${sizeMB} MB`,
  sizeBytes,
  sha256,
  sha1,
  releasedAt: new Date().toISOString(),
  githubRelease: `https://github.com/${GITHUB_REPO}/releases/tag/v${APK_VERSION}`,
};

const manifestBuffer = Buffer.from(JSON.stringify(manifest, null, 2), 'utf-8');

console.log(`⬆️  Uploading metadata manifest.json to Supabase bucket "${BUCKET}"…`);
const { error: uploadError } = await supabase.storage
  .from(BUCKET)
  .upload('manifest.json', manifestBuffer, {
    contentType: 'application/json',
    upsert: true,
  });

if (uploadError) {
  console.error('❌  Manifest upload failed:', uploadError.message);
  process.exit(1);
}

console.log('\n🎉  Release Manifest Published Successfully to Supabase!\n');
console.log('──────────────────────────────────────────────────────');
console.log(`📦  Version:        v${APK_VERSION}`);
console.log(`📏  Size:           ${sizeMB} MB`);
console.log(`🔗  GitHub APK URL: ${GITHUB_DOWNLOAD_URL}`);
console.log(`🔐  SHA-256:        ${sha256}`);
console.log(`🔐  SHA-1:          ${sha1}`);
console.log('──────────────────────────────────────────────────────');

const envSnippet = [
  `# Takwa APK Release v${APK_VERSION}`,
  `NEXT_PUBLIC_APK_URL=${GITHUB_DOWNLOAD_URL}`,
  `NEXT_PUBLIC_APK_VERSION=${APK_VERSION}`,
  `NEXT_PUBLIC_APK_SIZE=${sizeMB} MB`,
  `NEXT_PUBLIC_APK_SHA256=${sha256}`,
  `NEXT_PUBLIC_APK_SHA1=${sha1}`,
  `NEXT_PUBLIC_APK_RELEASED_AT=${manifest.releasedAt}`,
].join('\n');

console.log('\n📋  Environment Variables Configuration:');
console.log(envSnippet);
console.log('──────────────────────────────────────────────────────\n');

// Automatically update apps/web/.env and .env.local with new release values
const envPath = resolve(__dirname, '../.env');
if (existsSync(envPath)) {
  try {
    let envContent = readFileSync(envPath, 'utf8');
    const updateOrAppend = (key, val) => {
      const regex = new RegExp(`^${key}=.*$`, 'm');
      if (regex.test(envContent)) {
        envContent = envContent.replace(regex, `${key}=${val}`);
      } else {
        envContent += `\n${key}=${val}`;
      }
    };

    updateOrAppend('NEXT_PUBLIC_APK_URL', GITHUB_DOWNLOAD_URL);
    updateOrAppend('NEXT_PUBLIC_APK_VERSION', APK_VERSION);
    updateOrAppend('NEXT_PUBLIC_APK_SIZE', `${sizeMB} MB`);
    updateOrAppend('NEXT_PUBLIC_APK_SHA256', sha256);
    updateOrAppend('NEXT_PUBLIC_APK_SHA1', sha1);
    updateOrAppend('NEXT_PUBLIC_APK_RELEASED_AT', manifest.releasedAt);

    writeFileSync(envPath, envContent, 'utf8');
    console.log(`✅  Automatically updated environment in ${envPath}`);
  } catch (err) {
    console.error(`⚠️  Could not auto-update .env: ${err.message}`);
  }
}

console.log('\n💡  NEXT STEP (Host the APK binary):');
console.log(`    Upload the APK to GitHub Release v${APK_VERSION}:`);
console.log(`    gh release create v${APK_VERSION} "${targetApk}#takwa-v${APK_VERSION}.apk" --title "Takwa v${APK_VERSION}" --notes "Release v${APK_VERSION}"\n`);
