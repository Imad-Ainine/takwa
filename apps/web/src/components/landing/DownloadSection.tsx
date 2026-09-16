'use client';

import React, { useEffect, useRef, useState, useCallback, useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { Link } from '@/i18n/routing';

type PlatformKey = 'android' | 'ios';

interface DownloadSectionProps {
  apkUrl?: string;
  apkVersion?: string;
  apkSize?: string;
  sha256?: string;
  sha1?: string;
  iosUrl?: string;
}

// Simple SVG QR Code component (pattern-based placeholder that looks like a real QR)
function QRCodeDisplay({ url, alt }: { url: string; alt: string }) {
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null);

  useEffect(() => {
    if (!url) return;
    // Guards against a stale QR landing after a quick platform-tab switch:
    // this component is also remounted (via `key={url}`) on every url
    // change, but that only resets state for the *next* render — an
    // in-flight promise from the previous url could still resolve after.
    let cancelled = false;
    // Generate QR code using the qrcode library
    import('qrcode').then((QRCode) => {
      QRCode.toDataURL(url, {
        width: 220,
        margin: 2,
        color: {
          dark: '#c8a96e',
          light: '#04011e',
        },
        errorCorrectionLevel: 'H',
      }).then((dataUrl) => {
        if (!cancelled) setQrDataUrl(dataUrl);
      }).catch(() => {
        // Fallback - generate with white on dark
        QRCode.toDataURL(url, {
          width: 220,
          margin: 2,
        }).then((dataUrl) => {
          if (!cancelled) setQrDataUrl(dataUrl);
        });
      });
    });
    return () => {
      cancelled = true;
    };
  }, [url]);

  if (!qrDataUrl) {
    return (
      <div className="qr-placeholder">
        <div className="qr-loading-grid">
          {Array.from({ length: 81 }).map((_, i) => {
            const isDark = [0, 1, 2, 8, 9, 10, 18, 19, 20, 24, 28, 32, 36, 40, 48, 54, 63, 64, 65, 72, 73, 74].includes(i);
            return <div key={i} className={`qr-cell ${isDark ? 'qr-cell-dark' : ''}`} />;
          })}
        </div>
      </div>
    );
  }

  return (
    <div className="qr-image-wrap">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={qrDataUrl} alt={alt} className="qr-img" width={200} height={200} />
    </div>
  );
}

export default function DownloadSection({
  apkUrl = '',
  apkVersion = '',
  apkSize = '',
  sha256 = '',
  sha1 = '',
  iosUrl = '',
}: DownloadSectionProps) {
  const t = useTranslations('HomePage');
  const sectionRef = useRef<HTMLElement>(null);
  const [copiedSha, setCopiedSha] = useState<'sha256' | 'sha1' | null>(null);
  // Default to whichever platform actually has a live link — if only one of
  // the two is ready, land the visitor straight on it instead of an
  // "unavailable" tab.
  const [platform, setPlatform] = useState<PlatformKey>(apkUrl || !iosUrl ? 'android' : 'ios');

  const PLATFORMS = useMemo(
    () =>
      [
        { key: 'android', nameKey: 'downloadHub.platforms.android.name', statusKey: 'downloadHub.platforms.android.status', active: true, icon: '🤖' },
        { key: 'play', nameKey: 'downloadHub.platforms.play.name', statusKey: 'downloadHub.platforms.play.status', active: false, icon: '🏪' },
        { key: 'ios', nameKey: 'downloadHub.platforms.ios.name', statusKey: Boolean(iosUrl) ? 'downloadHub.platforms.ios.statusActive' : 'downloadHub.platforms.ios.status', active: Boolean(iosUrl), icon: '🍎' },
        { key: 'web', nameKey: 'downloadHub.platforms.web.name', statusKey: 'downloadHub.platforms.web.status', active: true, icon: '🌐' },
      ] as const,
    [iosUrl]
  );

  useEffect(() => {
    const el = sectionRef.current;
    if (!el) return;
    const pref = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (pref) {
      el.classList.add('download-visible');
      return;
    }
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('download-visible');
          observer.disconnect();
        }
      },
      { threshold: 0.08, rootMargin: '0px 0px -50px 0px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const copyHash = useCallback(async (type: 'sha256' | 'sha1', value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      setCopiedSha(type);
      setTimeout(() => setCopiedSha(null), 2500);
    } catch { /* clipboard access denied */ }
  }, []);

  const isAndroid = platform === 'android';
  const isAvailable = isAndroid ? Boolean(apkUrl) : Boolean(iosUrl);
  const downloadUrl = isAndroid ? (apkUrl || '#') : (iosUrl || '#');
  const downloadFilename = `takwa-v${apkVersion}.apk`;
  // Scanning the QR always lands somewhere useful, even pre-launch: the
  // platform's real link once it exists, otherwise the download page itself.
  const qrUrl = downloadUrl !== '#' ? downloadUrl : 'https://takwa-app.com/#download';
  // The native iOS app needs TestFlight (blocked on Apple Developer Program
  // signing — see docs/ios-testflight-setup.md). Until that link exists,
  // don't leave iPhone visitors with a dead "coming soon" button: point
  // them at the Web Companion instead, which already runs today and syncs
  // through the same Supabase backend the mobile app uses, and can be
  // added to the iPhone Home Screen for an app-like shortcut.
  const showIosInterim = !isAndroid && !isAvailable;

  return (
    <section ref={sectionRef} className="section download-section" id="download">
      <div className="container">
        {/* Section Header */}
        <div className="download-header">
          <div className="trust-badge" style={{ marginBottom: '20px' }}>
            <span className="dot" />
            {t('downloadHub.tag')}
          </div>
          <h2 className="gold-text download-section-title">{t('downloadHub.title')}</h2>
          <p className="download-section-subtitle">{t('downloadHub.subtitle')}</p>
        </div>

        <div className="download-layout">
          {/* === Main Download Card === */}
          <div className="mihrab-card download-main-card">
            {/* Card Glow Ornament */}
            <div className="download-card-glow" aria-hidden="true" />

            {/* Platform Switch */}
            <div className="platform-switch" role="tablist" aria-label={t('downloadHub.platformTabs.ariaLabel')}>
              <button
                type="button"
                role="tab"
                aria-selected={isAndroid}
                className={`platform-switch-btn ${isAndroid ? 'platform-switch-btn-active' : ''}`}
                onClick={() => setPlatform('android')}
              >
                <span className="platform-switch-icon" aria-hidden="true">🤖</span>
                {t('downloadHub.platformTabs.android')}
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={!isAndroid}
                className={`platform-switch-btn ${!isAndroid ? 'platform-switch-btn-active' : ''}`}
                onClick={() => setPlatform('ios')}
              >
                <span className="platform-switch-icon" aria-hidden="true">🍎</span>
                {t('downloadHub.platformTabs.ios')}
              </button>
            </div>

            {/* Top Section: QR + Info */}
            <div className="dl-top">
              {/* QR Code Block */}
              <div className="qr-block">
                <QRCodeDisplay
                  key={qrUrl}
                  url={qrUrl}
                  alt={isAndroid ? 'Scan to download the Takwa APK' : showIosInterim ? 'Scan to open the Takwa website' : 'Scan to open the Takwa iOS install link'}
                />
                <p className="qr-hint">
                  {isAndroid ? t('downloadHub.qrTitle') : showIosInterim ? t('downloadHub.qrTitleIosInterim') : t('downloadHub.qrTitleIos')}
                </p>
                <p className="qr-subhint">
                  {isAndroid ? t('downloadHub.qrSubtitle') : showIosInterim ? t('downloadHub.qrSubtitleIosInterim') : t('downloadHub.qrSubtitleIos')}
                </p>
              </div>

              {/* Meta Information */}
              <div className="dl-info">
                <div className="dl-platform-badge">
                  <span className="platform-logo" aria-hidden="true">{isAndroid ? '🤖' : '🍎'}</span>
                  <div>
                    <span className="platform-badge-name">
                      {isAndroid ? t('downloadHub.badgeAndroid') : showIosInterim ? t('downloadHub.badgeIosInterim') : t('downloadHub.badgeIos')}
                    </span>
                    {isAndroid && apkSize && (
                      <span className="platform-badge-size">
                        {t('downloadHub.badgeSize', { size: apkSize })}
                      </span>
                    )}
                  </div>
                </div>

                {/* Primary Download / Install Button */}
                {showIosInterim ? (
                  <>
                    <Link href="/login" className="btn-primary dl-btn" id="main-ios-interim-btn">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <path d="M13 2 3 14h7l-1 8 10-12h-7l1-8z" />
                      </svg>
                      {t('downloadHub.iosInterimCtaButton')}
                    </Link>
                    <p className="ios-interim-note">{t('downloadHub.iosInterimNote')}</p>
                  </>
                ) : isAvailable ? (
                  isAndroid ? (
                    <a
                      href={downloadUrl}
                      download={downloadFilename}
                      className="btn-primary dl-btn"
                      id="main-download-apk-btn"
                      aria-label={`Download Takwa APK version ${apkVersion}`}
                    >
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                        <polyline points="7 10 12 15 17 10" />
                        <line x1="12" y1="15" x2="12" y2="3" />
                      </svg>
                      {t('downloadHub.ctaButton', { version: apkVersion })}
                    </a>
                  ) : (
                    <a
                      href={downloadUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="btn-primary dl-btn"
                      id="main-download-ios-btn"
                      aria-label="Join the Takwa iOS beta on TestFlight"
                    >
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                        <polyline points="7 10 12 15 17 10" />
                        <line x1="12" y1="15" x2="12" y2="3" />
                      </svg>
                      {t('downloadHub.iosCtaButton')}
                    </a>
                  )
                ) : (
                  <div className="dl-btn-unavailable" id="download-unavailable-msg">
                    <span>⏳</span>
                    <span>{t('downloadHub.comingSoonBadge')}</span>
                  </div>
                )}

                {/* Checksum Verification (APK only — TestFlight/App Store builds are Apple-signed) */}
                {isAndroid && (sha256 || sha1) && (
                  <div className="checksum-block">
                    {sha256 && (
                      <div className="checksum-row">
                        <span className="checksum-label">{t('downloadHub.shaTitle')}</span>
                        <div className="checksum-value-wrap">
                          <code className="checksum-code">{sha256.slice(0, 16)}…</code>
                          <button
                            type="button"
                            className="copy-btn"
                            onClick={() => copyHash('sha256', sha256)}
                            aria-label="Copy SHA-256 hash"
                            title={t('downloadHub.copy')}
                          >
                            {copiedSha === 'sha256' ? '✓' : '⎘'}
                          </button>
                        </div>
                        {copiedSha === 'sha256' && (
                          <span className="copied-msg">{t('downloadHub.copied')}</span>
                        )}
                      </div>
                    )}
                    {sha1 && (
                      <div className="checksum-row">
                        <span className="checksum-label">{t('downloadHub.sha1Title')}</span>
                        <div className="checksum-value-wrap">
                          <code className="checksum-code">{sha1.slice(0, 16)}…</code>
                          <button
                            type="button"
                            className="copy-btn"
                            onClick={() => copyHash('sha1', sha1)}
                            aria-label="Copy SHA-1 hash"
                            title={t('downloadHub.copy')}
                          >
                            {copiedSha === 'sha1' ? '✓' : '⎘'}
                          </button>
                        </div>
                        {copiedSha === 'sha1' && (
                          <span className="copied-msg">{t('downloadHub.copied')}</span>
                        )}
                      </div>
                    )}
                  </div>
                )}

                {/* Security Trust Line */}
                <p className="security-trust-line">
                  🔒 {t('downloadHub.securityTrust')}
                </p>
              </div>
            </div>

            {/* Install Guide Steps */}
            <div className="install-guide">
              <h3 className="guide-title">
                {t(`downloadHub.${isAndroid ? 'installGuide' : showIosInterim ? 'installGuideIosInterim' : 'installGuideIos'}.title`)}
              </h3>
              <div className="guide-steps">
                {(['step1', 'step2', 'step3'] as const).map((step, i) => (
                  <div className="guide-step" key={step}>
                    <div className="step-number">{i + 1}</div>
                    <div>
                      <strong className="step-title">
                        {t(`downloadHub.${isAndroid ? 'installGuide' : showIosInterim ? 'installGuideIosInterim' : 'installGuideIos'}.${step}.title`)}
                      </strong>
                      <p className="step-desc">
                        {t(`downloadHub.${isAndroid ? 'installGuide' : showIosInterim ? 'installGuideIosInterim' : 'installGuideIos'}.${step}.desc`)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* === Side Panel: Platform Status === */}
          <div className="download-side-panel">
            <h3 className="side-title">{t('downloadHub.sideTitle')}</h3>
            <div className="platforms-list">
              {PLATFORMS.map((platformItem) => (
                <button
                  key={platformItem.key}
                  type="button"
                  className={`platform-item ${platformItem.active ? 'platform-active' : 'platform-coming'} ${(platformItem.key === 'android' || platformItem.key === 'ios') ? 'platform-item-clickable' : ''}`}
                  onClick={() => {
                    if (platformItem.key === 'android' || platformItem.key === 'ios') {
                      setPlatform(platformItem.key);
                    }
                  }}
                  disabled={platformItem.key !== 'android' && platformItem.key !== 'ios'}
                >
                  <span className="platform-icon">{platformItem.icon}</span>
                  <div className="platform-info">
                    <span className="platform-name">{t(platformItem.nameKey)}</span>
                    <span className={`platform-status ${platformItem.active ? 'status-active' : 'status-pending'}`}>
                      {platformItem.active ? '● ' : '○ '}
                      {t(platformItem.statusKey)}
                    </span>
                  </div>
                </button>
              ))}
            </div>

            {/* Privacy / Trust Card */}
            <div className="privacy-card">
              <div className="privacy-icon">🛡️</div>
              <div>
                <h4 className="privacy-title">{t('downloadHub.privacyTitle')}</h4>
                <p className="privacy-body">
                  {t('downloadHub.privacyBody')}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
