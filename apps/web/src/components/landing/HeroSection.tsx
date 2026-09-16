'use client';

import React, { useRef } from 'react';
import Image from 'next/image';
import { useTranslations } from 'next-intl';

interface HeroSectionProps {
  apkVersion?: string;
  apkSize?: string;
  apkUrl?: string;
  iosUrl?: string;
}

export default function HeroSection({
  apkVersion = '',
  apkSize = '',
  apkUrl = '#download',
  iosUrl = '',
}: HeroSectionProps) {
  const t = useTranslations('HomePage');
  const heroRef = useRef<HTMLDivElement>(null);
  const mockupRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);

  return (
    <section ref={heroRef} className="hero-section" id="hero">
      {/* Background Ornaments */}
      <div className="hero-glow-bg" aria-hidden="true" />
      <div className="islamic-pattern-bg hero-pattern-overlay" aria-hidden="true" />

      <div className="container hero-grid">
        {/* Left / Text Column */}
        <div ref={contentRef} className="hero-content">
          {/* Trust Badge */}
          <div className="hero-anim-badge">
            <span className="trust-badge">
              <span className="dot" />
              {t('heroBadge')}
            </span>
          </div>

          {/* Heading */}
          <h1 className="hero-title hero-anim-title">
            <span className="gold-text amiri">{t('title')}</span>
          </h1>

          {/* Subtitle */}
          <p className="hero-desc hero-anim-desc">{t('description')}</p>

          {/* Primary & Secondary CTAs */}
          <div className="hero-cta-group hero-anim-cta">
            <a
              href={apkUrl || '#download'}
              className="btn-primary hero-btn-main"
              id="hero-download-cta"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" y1="15" x2="12" y2="3" />
              </svg>
              <span>{t('heroCtaDownload')}</span>
              {apkVersion && (
                <span className="cta-sub-badge">v{apkVersion}{apkSize ? ` • ${apkSize}` : ''}</span>
              )}
            </a>

            <a href="#features" className="btn-outline">
              <span>{t('heroCtaExplore')}</span>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <line x1="5" y1="12" x2="19" y2="12" />
                <polyline points="12 5 19 12 12 19" />
              </svg>
            </a>
          </div>

          {/* iOS note — only shown once a TestFlight/App Store link exists */}
          {iosUrl && (
            <a href="#download" className="hero-ios-note hero-anim-cta">
              <span aria-hidden="true">🍎</span>
              <span>{t('heroIosNote')}</span>
            </a>
          )}

          {/* Value Props Pills */}
          <div className="hero-chips-wrap hero-anim-chips">
            <div className="value-chip">
              <span className="chip-icon">🕌</span>
              <span>{t('chipPrayer')}</span>
            </div>
            <div className="value-chip">
              <span className="chip-icon">⚖️</span>
              <span>{t('chipHisab')}</span>
            </div>
            <div className="value-chip">
              <span className="chip-icon">📖</span>
              <span>{t('chipQuran')}</span>
            </div>
            <div className="value-chip">
              <span className="chip-icon">🛡️</span>
              <span>{t('chipPrivacy')}</span>
            </div>
          </div>
        </div>

        {/* Right / 3D Mockup Visual Column */}
        <div ref={mockupRef} className="hero-visual">
          <div className="mockup-stage">
            {/* Ambient Backlight */}
            <div className="mockup-ambient-glow" aria-hidden="true" />

            {/* Secondary Phone (Background Angle) */}
            <div className="mockup-phone mockup-phone-secondary">
              <div className="phone-bezel">
                <div className="phone-speaker" />
                <div className="phone-screen-container">
                  <Image
                    src="/screenshots/1.webp"
                    alt="Takwa Prayer Schedule Screen"
                    width={260}
                    height={550}
                    className="phone-screen-img"
                    sizes="(max-width: 580px) 220px, 260px"
                    loading="lazy"
                    fetchPriority="low"
                    style={{ width: '100%', height: 'auto', aspectRatio: '580 / 1227', objectFit: 'cover' }}
                  />
                </div>
              </div>
            </div>

            {/* Primary Phone (Foreground Focal) */}
            <div className="mockup-phone mockup-phone-primary">
              <div className="phone-bezel">
                <div className="phone-dynamic-island" />
                <div className="phone-screen-container">
                  <Image
                    src="/screenshots/0.webp"
                    alt="Takwa Main Dashboard Screen"
                    width={290}
                    height={614}
                    className="phone-screen-img"
                    priority
                    fetchPriority="high"
                    decoding="sync"
                    sizes="(max-width: 580px) 240px, 290px"
                    style={{ width: '100%', height: 'auto', aspectRatio: '580 / 1227', objectFit: 'cover' }}
                  />
                </div>
              </div>

              {/* Floating Highlight Card 1: Next Prayer */}
              <div className="floating-card-chip card-prayer">
                <div className="floating-icon">🕋</div>
                <div className="floating-text">
                  <span className="floating-title">Fajr • 05:12 AM</span>
                  <span className="floating-desc">Adhan Notification Active</span>
                </div>
              </div>

              {/* Floating Highlight Card 2: Hisab Streak */}
              <div className="floating-card-chip card-streak">
                <div className="floating-icon">✨</div>
                <div className="floating-text">
                  <span className="floating-title">14-Day Streak</span>
                  <span className="floating-desc">Hisab Checklist Complete</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
