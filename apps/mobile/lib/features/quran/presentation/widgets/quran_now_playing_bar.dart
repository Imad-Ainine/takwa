import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/takwa_tappable.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import '../screens/quran_reader_screen.dart';
import 'reader/quran_reader_colors.dart';

/// App-wide transport bar for Quran recitation.
///
/// Whole-surah playback runs on quran_library's shared player, so it keeps
/// going after the reader closes — this is what makes that visible (and
/// controllable) anywhere in the app instead of only inside the reader's
/// audio row, where it used to be the only place the session could be seen.
class QuranNowPlayingBar extends ConsumerWidget {
  const QuranNowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioProvider);
    if (!audio.hasSession) return const SizedBox.shrink();

    final notifier = ref.read(quranAudioProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? context.colors.card : Colors.white;
    final fg = isDark ? Colors.white70 : context.colors.textPrimary;
    final dim = isDark ? Colors.white38 : Colors.black45;
    final surah = audio.sessionSurah != 0 ? audio.sessionSurah : audio.surah;

    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              TakwaTappable(
                onTap: () => _openReader(context, surah),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kReaderTealHdr,
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: audio.isPlaying ? kReaderGoldLight : Colors.white54,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TakwaTappable(
                  onTap: () => _openReader(context, surah),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedSurahName(context, surah),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                      Text(
                        audio.hasError
                            ? 'تعذّر تشغيل التلاوة'
                            : audio.ayah != 0
                            ? 'الآية ${localizedNumeral(context, audio.ayah)} • ${audio.speed}x'
                            : '',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 11,
                          color: audio.hasError ? Colors.redAccent : dim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => notifier.togglePlay(surah),
                icon: Icon(
                  audio.isLoading
                      ? Icons.hourglass_empty_rounded
                      : audio.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: fg,
                ),
                tooltip: audio.isPlaying ? 'إيقاف مؤقت' : 'استماع',
              ),
              IconButton(
                onPressed: notifier.stop,
                icon: Icon(Icons.close_rounded, color: dim, size: 20),
                tooltip: 'إيقاف',
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  void _openReader(BuildContext context, int surahNum) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(initialSurah: surahNum),
      ),
    );
  }
}
