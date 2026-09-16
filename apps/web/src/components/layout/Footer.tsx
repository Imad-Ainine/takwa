'use client';

import Image from 'next/image';
import {Link} from '@/i18n/routing';
import { useTranslations } from 'next-intl';

export default function Footer() {
	const currentYear = new Date().getFullYear();
	const t = useTranslations('Navigation');
	const th = useTranslations('HomePage');

	return (
		<footer className='footer'>
			<div className='container footer-content'>
				<div className='footer-brand'>
					<div className='logo'>
						<Image
							src='/logo.png'
							alt='Takwa Logo'
							width={132}
							height={60}
							className='logo-img'
							style={{ aspectRatio: '1492 / 678', height: 'auto' }}
						/>
					</div>
					<p className='footer-tagline'>
						{th('description')}
					</p>
				</div>

				<div className='footer-grid'>
					<div className='footer-column'>
						<h3>{t('home')}</h3>
						<ul>
							<li>
								<Link href='/'>{t('home')}</Link>
							</li>
							<li>
								<Link href='/support'>{t('support')}</Link>
							</li>
						</ul>
					</div>
					<div className='footer-column'>
						<h3>{t('legal')}</h3>
						<ul>
							<li>
								<Link href='/privacy'>{t('privacy')}</Link>
							</li>
							<li>
								<Link href='/terms'>{t('terms')}</Link>
							</li>
						</ul>
					</div>
				</div>
			</div>

			<div className='footer-bottom'>
				<div className='container'>
					<p>&copy; {currentYear} Takwa App. All rights reserved.</p>
				</div>
			</div>
		</footer>
	);
}
