'use client';

import React, { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';

interface PrayerSchedule {
  name: string;
  key: 'fajr' | 'dhuhr' | 'asr' | 'maghrib' | 'isha';
  time: string;
  hours: number;
  minutes: number;
}

export default function PrayerTimesTicker() {
  const t = useTranslations('HomePage.ticker');

  // Representative standard prayer timetable (dynamically updated relative to user time)
  const [schedule] = useState<PrayerSchedule[]>([
    { name: t('fajr'), key: 'fajr', time: '05:12', hours: 5, minutes: 12 },
    { name: t('dhuhr'), key: 'dhuhr', time: '12:45', hours: 12, minutes: 45 },
    { name: t('asr'), key: 'asr', time: '16:15', hours: 16, minutes: 15 },
    { name: t('maghrib'), key: 'maghrib', time: '18:50', hours: 18, minutes: 50 },
    { name: t('isha'), key: 'isha', time: '20:18', hours: 20, minutes: 18 },
  ]);

  const [nextPrayer, setNextPrayer] = useState<{ name: string; countdown: string }>({
    name: schedule[0].name,
    countdown: '00:00:00',
  });

  useEffect(() => {
    let isMounted = true;

    function updateCountdown() {
      if (!isMounted) return;
      const now = new Date();
      const currentMinutes = now.getHours() * 60 + now.getMinutes();

      let upcoming = schedule.find(
        (p) => p.hours * 60 + p.minutes > currentMinutes
      );

      const targetDate = new Date();
      if (!upcoming) {
        upcoming = schedule[0];
        targetDate.setDate(targetDate.getDate() + 1);
      }

      targetDate.setHours(upcoming.hours, upcoming.minutes, 0, 0);

      const diffMs = Math.max(0, targetDate.getTime() - now.getTime());
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      const diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
      const diffSecs = Math.floor((diffMs % (1000 * 60)) / 1000);

      const formattedCountdown = `${String(diffHours).padStart(2, '0')}:${String(
        diffMins
      ).padStart(2, '0')}:${String(diffSecs).padStart(2, '0')}`;

      setNextPrayer({
        name: upcoming.name,
        countdown: formattedCountdown,
      });
    }

    updateCountdown();
    const interval = setInterval(updateCountdown, 1000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [schedule]);


  return (
    <div className="prayer-ticker-wrap" aria-label="Daily Prayer Times Bar">
      <div className="container ticker-container">
        {/* Calligraphy Crest */}
        <div className="bismillah-crest">
          <span className="bismillah-arabic amiri">﷽</span>
        </div>

        {/* Next Prayer Live Pill */}
        <div className="next-prayer-pill">
          <span className="live-indicator" aria-hidden="true" />
          <span className="pill-label">{t('nextPrayer')}:</span>
          <span className="pill-name">{nextPrayer.name}</span>
          <span className="pill-countdown">{nextPrayer.countdown}</span>
        </div>

        {/* Schedule Ticker Items */}
        <div className="schedule-items">
          {schedule.map((p) => {
            const isNext = p.name === nextPrayer.name;
            return (
              <div
                key={p.key}
                className={`prayer-time-chip ${isNext ? 'is-next' : ''}`}
              >
                <span className="prayer-label">{t(p.key)}</span>
                <span className="prayer-hour">{p.time}</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
