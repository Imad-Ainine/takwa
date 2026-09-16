'use client';

import React, { useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';

const FEATURE_ICONS = [
  {
    key: 'prayerTimes',
    icon: '🕌',
    color: 'rgba(229, 185, 88, 0.15)',
    border: 'rgba(229, 185, 88, 0.3)',
  },
  {
    key: 'quran',
    icon: '📖',
    color: 'rgba(16, 185, 129, 0.15)',
    border: 'rgba(16, 185, 129, 0.3)',
  },
  {
    key: 'qibla',
    icon: '🧭',
    color: 'rgba(58, 175, 169, 0.15)',
    border: 'rgba(58, 175, 169, 0.3)',
  },
  {
    key: 'checklist',
    icon: '⚖️',
    color: 'rgba(229, 185, 88, 0.12)',
    border: 'rgba(229, 185, 88, 0.25)',
  },
  {
    key: 'azkar',
    icon: '📿',
    color: 'rgba(16, 185, 129, 0.12)',
    border: 'rgba(16, 185, 129, 0.25)',
  },
  {
    key: 'asma',
    icon: '✨',
    color: 'rgba(245, 223, 168, 0.12)',
    border: 'rgba(245, 223, 168, 0.3)',
  },
  {
    key: 'ramadan',
    icon: '🌙',
    color: 'rgba(58, 175, 169, 0.12)',
    border: 'rgba(58, 175, 169, 0.28)',
  },
  {
    key: 'notifications',
    icon: '🛡️',
    color: 'rgba(16, 185, 129, 0.1)',
    border: 'rgba(16, 185, 129, 0.22)',
  },
] as const;

export default function FeaturesSection() {
  const t = useTranslations('HomePage');
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = sectionRef.current;
    if (!el) return;
    const pref = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (pref) {
      el.classList.add('features-visible');
      return;
    }
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('features-visible');
          observer.disconnect();
        }
      },
      { threshold: 0.08, rootMargin: '0px 0px -50px 0px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <section ref={sectionRef} className="section features-section" id="features">
      <div className="container">
        {/* Section Header */}
        <div className="features-header">
          <div className="trust-badge" style={{ marginBottom: '20px' }}>
            <span className="dot" />
            {t('featuresTag')}
          </div>
          <h2 className="gold-text features-title">{t('featuresTitle')}</h2>
          <p className="features-subtitle">{t('featuresSubtitle')}</p>
        </div>

        {/* Features Grid */}
        <div className="features-grid">
          {FEATURE_ICONS.map(({ key, icon, color, border }, i) => (
            <div
              key={key}
              className="mihrab-card feature-card"
              style={
                {
                  '--feature-color': color,
                  '--feature-border': border,
                  '--card-delay': `${i * 0.06}s`,
                } as React.CSSProperties
              }
            >
              <div className="feature-icon-wrap">
                <div className="feature-icon-bg" style={{ background: color, borderColor: border }} />
                <span className="feature-icon" aria-hidden="true">{icon}</span>
              </div>
              <h3 className="feature-title">{t(`features.${key}.title`)}</h3>
              <p className="feature-desc">{t(`features.${key}.description`)}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
