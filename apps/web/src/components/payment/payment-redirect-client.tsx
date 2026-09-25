'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';

const APP_SCHEME = 'takwa://';

/**
 * Client half of the payment redirect hop: reads the `to` query parameter
 * (a `takwa://payment-*` deep link set by the mobile app when it creates
 * the Chargily checkout) and hands the browser over to the app. A visible
 * fallback link covers browsers that block custom-scheme navigation.
 */
export default function PaymentRedirectClient() {
	const searchParams = useSearchParams();
	const target = searchParams.get('to');
	const isValid = target !== null && target.startsWith(APP_SCHEME);
	const [hopped, setHopped] = useState(false);

	useEffect(() => {
		if (!isValid || target === null) return;
		window.location.replace(target);
		setHopped(true);
	}, [isValid, target]);

	return (
		<main
			id="main-content"
			className="flex min-h-screen flex-col items-center justify-center gap-6 bg-[#0d0a1a] px-6 text-center"
		>
			<h1 className="text-2xl font-semibold text-[#d4af37]">
				{hopped ? 'Opening the Takwa app…' : 'Preparing your return to Takwa…'}
			</h1>
			<p className="max-w-md text-sm leading-6 text-white/70" dir="rtl">
				إن لم يُفتح التطبيق تلقائياً، اضغط الزر أدناه للعودة إليه والتحقق من
				حالة الدفع.
			</p>
			{isValid && target !== null ? (
				<a
					href={target}
					className="rounded-full bg-[#d4af37] px-8 py-3 text-sm font-semibold text-[#0d0a1a] transition hover:brightness-110"
				>
					Open the Takwa app / فتح تطبيق تقوى
				</a>
			) : (
				<p className="text-sm text-white/50">
					This link is missing its app target. Return to the Takwa app to
					verify your payment.
				</p>
			)}
		</main>
	);
}
