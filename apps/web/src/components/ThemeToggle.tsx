'use client';

import * as React from 'react';
import { Moon, Sun } from 'lucide-react';
import { useTheme } from 'next-themes';

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);

  // Avoid Hydration Mismatch
  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <div style={{ width: 40, height: 40 }} />; // placeholder
  }

  return (
    <button
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      className="btn-outline"
      style={{ padding: '8px', borderRadius: '50%', border: 'none' }}
      aria-label="Toggle theme"
    >
      {theme === 'dark' ? (
        <Sun size={20} style={{ color: 'var(--gold-vibrant)' }} />
      ) : (
        <Moon size={20} style={{ color: 'var(--text-primary)' }} />
      )}
    </button>
  );
}
