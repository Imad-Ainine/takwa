import styles from './dashboard.module.css';

export default function DashboardLoading() {
	return (
		<div className={styles.page}>
			<div className={styles.layout}>

				{/* ── Sidebar skeletons ── */}
				<aside className={styles.sidebar}>
					<div className={`${styles.card} ${styles.skeleton}`} style={{ minHeight: '320px' }} aria-hidden="true" />
					<div className={`${styles.card} ${styles.skeleton}`} style={{ minHeight: '220px' }} aria-hidden="true" />
				</aside>

				{/* ── Main content skeletons ── */}
				<main className={styles.main}>
					<div className={`${styles.card} ${styles.skeleton}`} style={{ minHeight: '180px' }} aria-hidden="true" />
					<div className={`${styles.card} ${styles.skeleton}`} style={{ minHeight: '340px' }} aria-hidden="true" />
					<div className={`${styles.card} ${styles.skeleton}`} style={{ minHeight: '240px' }} aria-hidden="true" />
				</main>

			</div>
		</div>
	);
}
