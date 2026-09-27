import 'package:flutter/material.dart';
import '../../../data/quran_data.dart';
import '../../../data/quran_models.dart';
import '../../../utils/quran_helpers.dart';
import 'quran_reader_colors.dart';

class QuranReaderFontSizeSheet extends StatefulWidget {
  final double currentScale;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onReset;

  const QuranReaderFontSizeSheet({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
    required this.onReset,
  });

  @override
  State<QuranReaderFontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<QuranReaderFontSizeSheet> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.currentScale;
  }

  void _update(double val) {
    final clamped = val.clamp(0.85, 1.6);
    setState(() => _scale = clamped);
    widget.onScaleChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_scale * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2F20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  widget.onReset();
                  setState(() => _scale = 1.0);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    'الوضع الافتراضي (100%)',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: kReaderGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                'حجم الخط والصفحة: $percent%',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Presets row
          Row(
            children: [
              _presetChip('85%', 0.85),
              const SizedBox(width: 6),
              _presetChip('100%', 1.0),
              const SizedBox(width: 6),
              _presetChip('115%', 1.15),
              const SizedBox(width: 6),
              _presetChip('130%', 1.30),
              const SizedBox(width: 6),
              _presetChip('150%', 1.50),
            ],
          ),

          const SizedBox(height: 22),

          // Slider row with A- and A+ steppers
          Row(
            children: [
              GestureDetector(
                onTap: () => _update(_scale - 0.05),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text(
                      'A-',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                  ),
                  child: Slider(
                    value: _scale.clamp(0.85, 1.6),
                    min: 0.85,
                    max: 1.6,
                    activeColor: kReaderGold,
                    inactiveColor: Colors.white24,
                    onChanged: _update,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _update(_scale + 0.05),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text(
                      'A+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Informational note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: kReaderGold, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يحافظ التكبير على أسطر صفحة المصحف الـ 15 كاملة دون أي اختلال في رسم المصحف الشريف.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, double val) {
    final selected = (_scale - val).abs() < 0.04;
    return Expanded(
      child: GestureDetector(
        onTap: () => _update(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? kReaderGold : Colors.white10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? kReaderGoldLight : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF0A2818) : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Surah Picker Sheet ──────────────────────────────────────
class QuranSurahPickerSheet extends StatefulWidget {
  final int currentSurah;

  /// Surah the audio session is currently loaded with (0 when nothing is).
  final int playingSurah;
  final ValueChanged<SurahMeta> onSelectSurah;
  final ValueChanged<SurahMeta> onPlaySurah;

  const QuranSurahPickerSheet({
    super.key,
    required this.currentSurah,
    required this.playingSurah,
    required this.onSelectSurah,
    required this.onPlaySurah,
  });

  @override
  State<QuranSurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<QuranSurahPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kSurahData.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.nameAr.contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.number.toString() == q;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          const Text(
            'فهرس سور القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kReaderGold,
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: const TextStyle(fontFamily: 'Amiri', color: Colors.white),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة أو رقمها...',
              hintStyle: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                color: Colors.white38,
                fontSize: 13,
              ),
              prefixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Surah list
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (ctx, idx) {
                final surah = filtered[idx];
                final isCurrent = surah.number == widget.currentSurah;
                return ListTile(
                  onTap: () => widget.onSelectSurah(surah),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? kReaderGold
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ص ${surah.startPage}',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 11,
                        color: isCurrent
                            ? const Color(0xFF0F261C)
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    surah.nameAr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? kReaderGoldLight : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${surah.type == 'meccan' ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آيات • الجزء ${surah.juzNumber}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play this surah from the index — the row itself jumps
                      // the reader, so without this the only way to start
                      // listening is to navigate first.
                      IconButton(
                        onPressed: () => widget.onPlaySurah(surah),
                        tooltip: surah.number == widget.playingSurah
                            ? 'إيقاف مؤقت'
                            : 'استماع',
                        icon: Icon(
                          surah.number == widget.playingSurah
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: surah.number == widget.playingSurah
                              ? kReaderGold
                              : Colors.white54,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent ? kReaderGold : Colors.white24,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${surah.number}',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? kReaderGold : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Juz Picker Sheet ────────────────────────────────────────
class QuranJuzPickerSheet extends StatelessWidget {
  final int currentJuz;
  final ValueChanged<int> onSelectJuz;

  const QuranJuzPickerSheet({
    super.key,
    required this.currentJuz,
    required this.onSelectJuz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'أجزاء القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kReaderGold,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: 30,
              itemBuilder: (ctx, idx) {
                final juzNum = idx + 1;
                final startPage = juzToPage(juzNum);
                final isSelected = juzNum == currentJuz;
                return GestureDetector(
                  onTap: () => onSelectJuz(juzNum),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? kReaderGold : Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? kReaderGoldLight : Colors.white12,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'الجزء $juzNum',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF0A2818)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'صفحة $startPage',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF0A2818).withValues(alpha: 0.8)
                                : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reciter Picker Sheet ────────────────────────────────────
class QuranReciterSheet extends StatelessWidget {
  final String currentReciterId;
  final ValueChanged<QuranReciter> onSelectReciter;

  const QuranReciterSheet({
    super.key,
    required this.currentReciterId,
    required this.onSelectReciter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'اختيار القارئ الصوتي',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kReaderGold,
            ),
          ),
          const SizedBox(height: 14),
          ...kDefaultReciters.map((r) {
            final isSelected = r.id == currentReciterId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? kReaderGold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? kReaderGold : Colors.white12,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  onTap: () => onSelectReciter(r),
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? kReaderGold : Colors.white38,
                  ),
                  title: Text(
                    r.nameAr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  subtitle: Text(
                    r.nameEn,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Download Audio Sheet ────────────────────────────────────
class QuranDownloadSheet extends StatelessWidget {
  final SurahMeta surah;
  final VoidCallback onDownload;

  const QuranDownloadSheet({
    super.key,
    required this.surah,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تحميل سورة ${surah.nameAr}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kReaderGold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'عدد الآيات: ${surah.ayahCount} • الحجم التقديري: ~${(surah.ayahCount * 0.08).toStringAsFixed(1)} ميجابايت',
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onDownload,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5234),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A5234).withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تحميل السورة للاستماع دون إنترنت',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Khatma Stats Sheet ──────────────────────────────────────
class QuranKhatmaStatsSheet extends StatelessWidget {
  final int pagesRead;
  final int currentPage;
  final DateTime sessionStart;

  const QuranKhatmaStatsSheet({
    super.key,
    required this.pagesRead,
    required this.currentPage,
    required this.sessionStart,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedMinutes = DateTime.now().difference(sessionStart).inMinutes;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'إحصائيات جلسة القراءة',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kReaderGold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statCard(
                'الصفحات المقروءة',
                '$pagesRead صفحة',
                Icons.menu_book_rounded,
              ),
              const SizedBox(width: 10),
              _statCard(
                'مدة القراءة',
                '$elapsedMinutes دقيقة',
                Icons.timer_outlined,
              ),
              const SizedBox(width: 10),
              _statCard(
                'الصفحة الحالية',
                '$currentPage / 604',
                Icons.auto_stories_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: const Center(
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: kReaderGold, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    ),
  );
}
