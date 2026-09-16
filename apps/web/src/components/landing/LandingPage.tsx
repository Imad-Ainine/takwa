import HeroSection from '@/components/landing/HeroSection';
import FeaturesSection from '@/components/landing/FeaturesSection';
import SpiritualQuoteBanner from '@/components/landing/SpiritualQuoteBanner';
import ScreenshotsShowcase from '@/components/landing/ScreenshotsShowcase';
import DownloadSection from '@/components/landing/DownloadSection';

interface HomeProps {
  apkUrl?: string;
  apkVersion?: string;
  apkSize?: string;
  sha256?: string;
  sha1?: string;
  iosUrl?: string;
}

export default function LandingPage({
  apkUrl,
  apkVersion,
  apkSize,
  sha256,
  sha1,
  iosUrl,
}: HomeProps) {
  return (
    <main id="main-content">
      <HeroSection
        apkUrl={apkUrl}
        apkVersion={apkVersion}
        apkSize={apkSize}
        iosUrl={iosUrl}
      />
      <FeaturesSection />
      <SpiritualQuoteBanner />
      <ScreenshotsShowcase />
      <DownloadSection
        apkUrl={apkUrl}
        apkVersion={apkVersion}
        apkSize={apkSize}
        sha256={sha256}
        sha1={sha1}
        iosUrl={iosUrl}
      />
    </main>
  );
}
