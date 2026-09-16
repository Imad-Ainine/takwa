'use client';

import React, { useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';

export default function SpiritualQuoteBanner() {
  const t = useTranslations('HomePage.quote');
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = sectionRef.current;
    if (!el) return;
    const pref = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (pref) {
      el.classList.add('quote-visible');
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('quote-visible');
          observer.disconnect();
        }
      },
      { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <section ref={sectionRef} className="quote-banner-section" aria-label="Quranic Verse">
      <div className="container quote-banner-inner">
        <div className="arch-left" aria-hidden="true" />
        <div className="arch-right" aria-hidden="true" />

        <div className="quote-content">
          <div className="crescent-ornament" aria-hidden="true">
            <span>☽</span>
          </div>
          <p className="arabic-verse amiri">{t('arabic')}</p>
          <p className="translation-text">{t('translation')}</p>
          <p className="surah-ref">{t('surah')}</p>
        </div>
      </div>
    </section>
  );
}
