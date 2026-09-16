'use client';

import React from 'react';
import { useTranslations } from 'next-intl';

export default function TermsOfService() {
	const t = useTranslations('Terms');

	return (
		<div className='policy-page'>
			<div className='container'>
				<h1 className='gold-text amiri'>{t('title')}</h1>
				<p className='last-updated'>{t('lastUpdated')}</p>

				<section className='policy-section'>
					<h2>{t('sections.agree.title')}</h2>
					<p>{t('sections.agree.content')}</p>
				</section>

				<section className='policy-section'>
					<h2>{t('sections.use.title')}</h2>
					<p>{t('sections.use.content')}</p>
				</section>

				<section className='policy-section'>
					<h2>{t('sections.ip.title')}</h2>
					<p>{t('sections.ip.content')}</p>
				</section>

				<section className='policy-section'>
					<h2>{t('sections.disclaimer.title')}</h2>
					<p>{t('sections.disclaimer.content')}</p>
				</section>

				<section className='policy-section'>
					<h2>{t('sections.liability.title')}</h2>
					<p>{t('sections.liability.content')}</p>
				</section>

				<section className='policy-section'>
					<h2>{t('sections.changes.title')}</h2>
					<p>{t('sections.changes.content')}</p>
				</section>

				<section className='policy-section'>
					<h2>{t('sections.contact.title')}</h2>
					<p>
						{t('sections.contact.content')}
						<span className='gold-text'> legal@takwa-app.com</span>
					</p>
				</section>
			</div>
		</div>
	);
}
