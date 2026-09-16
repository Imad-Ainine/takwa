'use client';

import React, { useState, useEffect } from 'react';
import { Link } from '@/i18n/routing';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import LanguageSwitcher from '../common/LanguageSwitcher';

export default function Navbar() {
  const t = useTranslations('Navigation');
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu on resize
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 860) setMobileOpen(false);
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return (
    <>
      <nav className={`navbar ${isScrolled ? 'navbar-scrolled' : ''}`} role="navigation" aria-label="Main Navigation">
        <div className="container nav-content">
          {/* Logo */}
          <Link href="/" className="logo" aria-label="Takwa Home">
            <Image
              src="/logo.png"
              alt="Takwa Logo"
              width={132}
              height={60}
              className="logo-img"
              sizes="132px"
              priority
              style={{ aspectRatio: '1492 / 678', height: 'auto' }}
            />
          </Link>

          {/* Desktop Nav Links */}
          <div className="nav-links">
            <a href="#features" className="nav-link">{t('features')}</a>
            <a href="#screenshots" className="nav-link">{t('screenshots')}</a>
            <Link href="/support" className="nav-link">{t('support')}</Link>
            <Link href="/privacy" className="nav-link">{t('privacy')}</Link>
            <LanguageSwitcher />
            <a
              href="#download"
              className="btn-primary nav-cta"
              id="nav-download-btn"
            >
              {t('download')}
            </a>
          </div>

          {/* Mobile Hamburger */}
          <button
            type="button"
            id="mobile-menu-toggle"
            className={`hamburger ${mobileOpen ? 'hamburger-open' : ''}`}
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-expanded={mobileOpen}
            aria-label="Toggle navigation menu"
          >
            <span className="ham-bar" />
            <span className="ham-bar" />
            <span className="ham-bar" />
          </button>
        </div>

        {/* Mobile Drawer */}
        {mobileOpen && (
          <div className="mobile-drawer" role="dialog" aria-modal="true" aria-label="Mobile Navigation">
            <div className="mobile-nav-links">
              <a href="#features" className="mobile-nav-link" onClick={() => setMobileOpen(false)}>
                {t('features')}
              </a>
              <a href="#screenshots" className="mobile-nav-link" onClick={() => setMobileOpen(false)}>
                {t('screenshots')}
              </a>
              <Link href="/support" className="mobile-nav-link" onClick={() => setMobileOpen(false)}>
                {t('support')}
              </Link>
              <Link href="/privacy" className="mobile-nav-link" onClick={() => setMobileOpen(false)}>
                {t('privacy')}
              </Link>
              <div className="mobile-lang-wrap">
                <LanguageSwitcher />
              </div>
              <a
                href="#download"
                className="btn-primary mobile-cta-btn"
                onClick={() => setMobileOpen(false)}
              >
                {t('download')}
              </a>
            </div>
          </div>
        )}
      </nav>
    </>
  );
}
