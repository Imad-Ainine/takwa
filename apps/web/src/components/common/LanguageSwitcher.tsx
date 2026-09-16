'use client';

import { useLocale } from 'next-intl';
import { usePathname, useRouter } from '@/i18n/routing';
import { useTransition, useState, useRef, useEffect } from 'react';

const LOCALES = [
	{ code: 'ar', label: 'العربية', short: 'عربي', dir: 'rtl' },
	{ code: 'en', label: 'English', short: 'EN', dir: 'ltr' },
	{ code: 'fr', label: 'Français', short: 'FR', dir: 'ltr' },
] as const;

type LocaleCode = (typeof LOCALES)[number]['code'];

export default function LanguageSwitcher() {
	const currentLocale = useLocale() as LocaleCode;
	const router = useRouter();
	const pathname = usePathname();
	const [isPending, startTransition] = useTransition();
	const [isOpen, setIsOpen] = useState(false);
	const dropdownRef = useRef<HTMLDivElement>(null);

	const activeLocaleObj =
		LOCALES.find((l) => l.code === currentLocale) || LOCALES[0];

	function switchLocale(nextLocale: LocaleCode) {
		if (nextLocale === currentLocale) {
			setIsOpen(false);
			return;
		}

		setIsOpen(false);
		startTransition(() => {
			router.replace(pathname, { locale: nextLocale });
		});
	}

	// Close dropdown when clicking outside
	useEffect(() => {
		function handleClickOutside(event: MouseEvent) {
			if (
				dropdownRef.current &&
				!dropdownRef.current.contains(event.target as Node)
			) {
				setIsOpen(false);
			}
		}

		if (isOpen) {
			document.addEventListener('mousedown', handleClickOutside);
		}
		return () => {
			document.removeEventListener('mousedown', handleClickOutside);
		};
	}, [isOpen]);

	return (
		<div className="lang-switcher-wrapper" ref={dropdownRef} dir="ltr">
			{/* Segmented control for larger screens */}
			<div className="segmented-control">
				{LOCALES.map((l) => {
					const isActive = currentLocale === l.code;
					return (
						<button
							key={l.code}
							type="button"
							onClick={() => switchLocale(l.code)}
							className={`segment-btn ${isActive ? 'active' : ''}`}
							disabled={isPending}
							aria-label={`Switch to ${l.label}`}
							aria-pressed={isActive}
						>
							<span className="lang-name">{l.short}</span>
						</button>
					);
				})}
			</div>

			{/* Dropdown toggle for compact spaces / mobile */}
			<div className="dropdown-container">
				<button
					type="button"
					className={`dropdown-trigger ${isOpen ? 'open' : ''}`}
					onClick={() => setIsOpen((prev) => !prev)}
					disabled={isPending}
					aria-expanded={isOpen}
					aria-haspopup="listbox"
					aria-label={`Select language (current: ${activeLocaleObj.label})`}
				>
					<svg
						className="globe-icon"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						strokeWidth="2"
						strokeLinecap="round"
						strokeLinejoin="round"
						aria-hidden="true"
					>
						<circle cx="12" cy="12" r="10" />
						<line x1="2" y1="12" x2="22" y2="12" />
						<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
					</svg>
					<span className="current-code">{activeLocaleObj.short}</span>
					<svg
						className={`chevron-icon ${isOpen ? 'rotated' : ''}`}
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						strokeWidth="2.5"
						strokeLinecap="round"
						strokeLinejoin="round"
						aria-hidden="true"
					>
						<polyline points="6 9 12 15 18 9" />
					</svg>
				</button>

				{isOpen && (
					<ul className="dropdown-menu" role="listbox">
						{LOCALES.map((l) => {
							const isActive = currentLocale === l.code;
							return (
								<li key={l.code} role="option" aria-selected={isActive}>
									<button
										type="button"
										className={`menu-item ${isActive ? 'selected' : ''}`}
										onClick={() => switchLocale(l.code)}
										dir={l.dir}
										aria-label={`Switch language to ${l.label}`}
									>
										<span className="item-label">{l.label}</span>
										<span className="item-badge">{l.code.toUpperCase()}</span>
										{isActive && (
											<svg
												className="check-icon"
												viewBox="0 0 24 24"
												fill="none"
												stroke="currentColor"
												strokeWidth="2.5"
												strokeLinecap="round"
												strokeLinejoin="round"
											>
												<polyline points="20 6 9 17 4 12" />
											</svg>
										)}
									</button>
								</li>
							);
						})}
					</ul>
				)}
			</div>
		</div>
	);
}
