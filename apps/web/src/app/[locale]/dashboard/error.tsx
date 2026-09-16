'use client';

import { useTranslations } from 'next-intl';
import { useEffect } from 'react';
import styles from './dashboard.module.css';

export default function DashboardError({
	error,
	reset,
}: {
	error: Error & { digest?: string };
	reset: () => void;
}) {
	const t = useTranslations('Dashboard');

	useEffect(() => {
		console.error(error);
	}, [error]);

	return (
		<div className={styles.page}>
			<div className={`${styles.card} ${styles.welcomeCard}`} style={{ maxWidth: 420 }}>
				<div className={styles.avatarRing}>
					<span className={styles.avatarEmoji}>⚠️</span>
				</div>
				<h1 className={`amiri gold-text ${styles.greeting}`}>{t('errorTitle')}</h1>
				<p className={styles.welcome}>{t('errorMessage')}</p>
				<button type="button" className="btn-outline" onClick={reset}>
					{t('retry')}
				</button>
			</div>
		</div>
	);
}
