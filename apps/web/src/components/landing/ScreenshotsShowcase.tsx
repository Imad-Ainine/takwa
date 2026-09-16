'use client';

import React, { useEffect, useRef, useState } from 'react';
import Image from 'next/image';
import { useTranslations } from 'next-intl';

type TabKey = 'all' | 'worship' | 'quran' | 'habits' | 'adhkar';

const SCREENSHOTS = [
  { index: 0, tab: 'worship' as TabKey },  // Home – prayer times & countdown
  { index: 1, tab: 'habits' as TabKey },   // Statistics – weekly performance
  { index: 2, tab: 'quran' as TabKey },    // Quran reader – Surah Al-Fatiha
  { index: 3, tab: 'quran' as TabKey },    // Khatma screen – start a new reading
  { index: 4, tab: 'quran' as TabKey },    // Quran surah list (free reading)
  { index: 5, tab: 'adhkar' as TabKey },   // App drawer / navigation hub
  { index: 6, tab: 'worship' as TabKey },  // Qiyam night prayer screen
  { index: 7, tab: 'worship' as TabKey },  // Home (alternate light mode)
  { index: 8, tab: 'habits' as TabKey },   // Statistics – worship completion
  { index: 9, tab: 'worship' as TabKey },  // Settings – adhan & notification
];

const TABS: TabKey[] = ['all', 'worship', 'quran', 'habits', 'adhkar'];

export default function ScreenshotsShowcase() {
  const t = useTranslations('HomePage.showcase');
  const sectionRef = useRef<HTMLElement>(null);
  const [activeTab, setActiveTab] = useState<TabKey>('all');
  const [selectedIdx, setSelectedIdx] = useState(0);

  const filteredShots = SCREENSHOTS.filter(
    (s) => activeTab === 'all' || s.tab === activeTab
  );

  const selectedShot = filteredShots[selectedIdx] ?? filteredShots[0];

  useEffect(() => {
    const el = sectionRef.current;
    if (!el) return;
    const pref = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (pref) {
      el.classList.add('showcase-visible');
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('showcase-visible');
          observer.disconnect();
        }
      },
      { threshold: 0.08, rootMargin: '0px 0px -50px 0px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <section ref={sectionRef} className="section screenshots-section" id="screenshots">
      <div className="container">
        {/* Header */}
        <div className="screenshots-header">
          <div className="trust-badge" style={{ marginBottom: '20px' }}>
            <span className="dot" />
            {t('tag')}
          </div>
          <h2 className="gold-text screenshots-title">{t('title')}</h2>
          <p className="screenshots-subtitle">{t('subtitle')}</p>
        </div>

        {/* Tabs Navigation */}
        <div className="tabs-nav" role="tablist" aria-label="Screenshot categories">
          {TABS.map((tab) => (
            <button
              key={tab}
              type="button"
              role="tab"
              aria-selected={activeTab === tab}
              aria-label={t(`tabs.${tab}`)}
              className={`tab-nav-item ${activeTab === tab ? 'active' : ''}`}
              onClick={() => {
                setActiveTab(tab);
                setSelectedIdx(0);
              }}
            >
              {t(`tabs.${tab}`)}
            </button>
          ))}
        </div>

        {/* Main Showcase Stage */}
        <div className="screenshots-stage">
          {/* Featured Large Preview */}
          <div className="featured-preview">
            <div className="featured-phone-frame">
              <div className="featured-dynamic-island" />
              {selectedShot && (
                <Image
                  key={`${selectedShot.index}-${activeTab}`}
                  src={`/screenshots/${selectedShot.index}.webp`}
                  alt={t(`items.${selectedShot.index}.title` as Parameters<typeof t>[0])}
                  width={286}
                  height={605}
                  className="featured-screen-img w-full"
                  sizes="(max-width: 600px) 240px, 286px"
                  style={{ width: '100%', height: 'auto', aspectRatio: '580 / 1227', objectFit: 'contain', borderRadius: "32px" }}
                />
              )}
            </div>
            {selectedShot && (
              <div className="featured-caption">
                <h3 className="caption-title">{t(`items.${selectedShot.index}.title` as Parameters<typeof t>[0])}</h3>
                <p className="caption-desc">{t(`items.${selectedShot.index}.desc` as Parameters<typeof t>[0])}</p>
              </div>
            )}
          </div>

          {/* Thumbnails Grid */}
          <div className="thumbs-grid">
            {filteredShots.map((shot, i) => (
              <button
                key={shot.index}
                type="button"
                className={`thumb-grid-item ${selectedIdx === i ? 'active' : ''}`}
                onClick={() => setSelectedIdx(i)}
                aria-label={t(`items.${shot.index}.title` as Parameters<typeof t>[0])}
                aria-pressed={selectedIdx === i}
              >
                <div className="thumb-phone-frame">
                  <Image
                    src={`/screenshots/${shot.index}.webp`}
                    alt={t(`items.${shot.index}.title` as Parameters<typeof t>[0])}
                    width={110}
                    height={233}
                    className="thumb-screen-img"
                    sizes="(max-width: 600px) 78px, (max-width: 900px) 90px, 110px"
                    style={{ width: '100%', height: 'auto', aspectRatio: '580 / 1227', objectFit: 'contain', borderRadius: "12px" }}
                  />
                  {selectedIdx === i && <div className="thumb-active-overlay" />}
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
