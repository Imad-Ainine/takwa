import { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Takwa - Your Islamic Companion',
    short_name: 'Takwa',
    description: 'The most beautiful Islamic app for prayer times, Quran, and spiritual growth.',
    start_url: '/',
    display: 'standalone',
    background_color: '#04011e',
    theme_color: '#c8a96e',
    icons: [
      {
        src: '/android-chrome-192x192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/android-chrome-512x512.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  };
}
