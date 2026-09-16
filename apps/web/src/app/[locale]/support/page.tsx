"use client";

import React from 'react';
import { useTranslations } from 'next-intl';

export default function Support() {
  const t = useTranslations('Support');

  return (
    <div className="support-page">
      <div className="container">
        <div className="support-header">
          <h1 className="gold-text amiri">{t('title')}</h1>
          <p>{t('subtitle')}</p>
        </div>

        <div className="support-grid">
          <div className="premium-card support-card">
            <div className="icon">📧</div>
            <h2>{t('cards.email.title')}</h2>
            <p>{t('cards.email.content')}</p>
            <a href="mailto:support@takwa-app.com" className="support-link gold-text">support@takwa-app.com</a>
          </div>

          <div className="premium-card support-card">
            <div className="icon">💬</div>
            <h2>{t('cards.social.title')}</h2>
            <p>{t('cards.social.content')}</p>
            <div className="social-links">
              <span className="gold-text">Twitter</span>
              <span className="gold-text">Instagram</span>
              <span className="gold-text">Facebook</span>
            </div>
          </div>

          <div className="premium-card support-card">
            <div className="icon">❓</div>
            <h2>{t('cards.faq.title')}</h2>
            <p>{t('cards.faq.content')}</p>
            <button type="button" className="btn-outline" style={{ marginTop: '10px' }}>{t('cards.faq.button')}</button>
          </div>
        </div>

        <div className="contact-form-section">
          <h2 className="amiri gold-text">{t('form.title')}</h2>
          <form className="contact-form">
            <div className="form-group">
              <label>{t('form.name')}</label>
              <input type="text" placeholder={t('form.placeholderName')} />
            </div>
            <div className="form-group">
              <label>{t('form.email')}</label>
              <input type="email" placeholder={t('form.placeholderEmail')} />
            </div>
            <div className="form-group">
              <label>{t('form.message')}</label>
              <textarea placeholder={t('form.placeholderMessage')} rows={5}></textarea>
            </div>
            <button type="submit" className="btn-primary" onClick={(e) => e.preventDefault()}>
              {t('form.submit')}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
