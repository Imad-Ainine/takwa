'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useRouter } from '@/i18n/routing';
import { createClient } from '@/lib/supabase/client';
import styles from './login.module.css';

/**
 * Foundation piece for the Web Companion Dashboard roadmap item (see the
 * engineering audit's §8): signs a user into the same Supabase project
 * the mobile app already uses. Deliberately just email/password for now —
 * mobile also supports Google Sign-In, but that needs its own OAuth
 * client configured for the web origin, which is a separate, scoped
 * follow-up rather than part of standing this foundation up.
 */
export default function LoginPage() {
	const t = useTranslations('Auth');
	const router = useRouter();
	const [email, setEmail] = useState('');
	const [password, setPassword] = useState('');
	const [error, setError] = useState<string | null>(null);
	const [loading, setLoading] = useState(false);

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		setError(null);
		setLoading(true);

		try {
			const supabase = createClient();
			const { error: signInError } = await supabase.auth.signInWithPassword({
				email,
				password,
			});

			if (signInError) {
				setError(t('errorInvalidCredentials'));
				setLoading(false);
				return;
			}
		} catch (err: unknown) {
			console.error('Login error:', err);
			const message =
				err instanceof Error ? err.message : t('errorInvalidCredentials');
			setError(message);
			setLoading(false);
			return;
		}

		// Server Components (the dashboard) read the session server-side, so
		// they need a real navigation + refresh, not just client-side state,
		// to see the new cookies as signed in.
		router.push('/dashboard');
		router.refresh();
	}

	return (
		<div className={styles.page}>
			<form className={styles.card} onSubmit={handleSubmit}>
				<h1 className="amiri gold-text">{t('title')}</h1>
				<p className={styles.subtitle}>{t('subtitle')}</p>

				<label className={styles.field}>
					<span>{t('email')}</span>
					<input
						type="email"
						required
						autoComplete="email"
						value={email}
						onChange={(e) => setEmail(e.target.value)}
						placeholder={t('emailPlaceholder')}
					/>
				</label>

				<label className={styles.field}>
					<span>{t('password')}</span>
					<input
						type="password"
						required
						autoComplete="current-password"
						value={password}
						onChange={(e) => setPassword(e.target.value)}
						placeholder={t('passwordPlaceholder')}
					/>
				</label>

				{error && <p className={styles.error}>{error}</p>}

				<button
					type="submit"
					className={`btn-primary ${styles.submit}`}
					disabled={loading}
				>
					{loading ? t('signingIn') : t('submit')}
				</button>

				<p className={styles.note}>{t('mobileAccountNote')}</p>
			</form>
		</div>
	);
}
