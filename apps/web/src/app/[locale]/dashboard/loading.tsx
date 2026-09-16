import styles from './dashboard.module.css';

export default function DashboardLoading() {
	return (
		<div className={styles.page}>
			<div className={styles.grid}>
				<div className={`${styles.card} ${styles.welcomeCard} ${styles.skeleton}`} aria-hidden="true" />
				<div className={`${styles.card} ${styles.downloadCard} ${styles.skeleton}`} aria-hidden="true" />
			</div>
			<div className={styles.sections}>
				<div className={`${styles.card} ${styles.skeleton}`} aria-hidden="true" />
				<div className={`${styles.card} ${styles.skeleton}`} aria-hidden="true" />
				<div className={`${styles.card} ${styles.skeleton}`} aria-hidden="true" />
			</div>
		</div>
	);
}
