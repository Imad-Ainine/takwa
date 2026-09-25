import { Suspense } from 'react';

import PaymentRedirectClient from '@/components/payment/payment-redirect-client';

/**
 * Landing hop for the Chargily hosted checkout: the payment API only
 * accepts http(s) success/failure URLs, so after the card attempt the
 * browser lands here and the client component forwards to the mobile
 * app's custom scheme (`takwa://payment-*`).
 */
export default function PaymentRedirectPage() {
	return (
		<Suspense fallback={null}>
			<PaymentRedirectClient />
		</Suspense>
	);
}
