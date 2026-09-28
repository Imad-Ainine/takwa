import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/data/pdf_download_service.dart';
import 'package:takwa/features/books/providers/pdf_session_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

class BookPdfReaderScreen extends ConsumerStatefulWidget {
  final IslamicBook book;

  const BookPdfReaderScreen({super.key, required this.book});

  @override
  ConsumerState<BookPdfReaderScreen> createState() =>
      _BookPdfReaderScreenState();
}

class _BookPdfReaderScreenState extends ConsumerState<BookPdfReaderScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ── PDF viewer ────────────────────────────
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController = PdfViewerController();

  // ── Download state ────────────────────────
  File? _localFile;
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  String? _error;
  StreamController<double>? _progressCtrl;

  // ── Text Selection ────────────────────────
  String _selectedText = '';
  bool _isTextSelected = false;

  // ── UI visibility animation ───────────────
  bool _showUI = true;
  late AnimationController _uiAnim;

  // ── Reconstructed tap (see _trackTapUp) ───
  int _pointers = 0;
  Offset? _tapDownPos;
  Duration? _tapDownTime;
  Duration? _lastTapUpTime;

  // ── Session Notifier ──────────────────────
  late PdfSessionNotifier _sessionNotifier;

  // ── Convenience getter ────────────────────
  String get _bookId => widget.book.id;

  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _uiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);

    // Load persisted session (page + timer)
    _sessionNotifier = ref.read(pdfSessionProvider(_bookId).notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionNotifier.loadSession(_bookId);
    });

    // Kick off PDF download
    if (widget.book.pdfUrl != null) {
      _startDownload();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiAnim.dispose();
    _pdfController.dispose();
    _progressCtrl?.close();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// The reading timer is wall-clock, so it has to stop with the screen:
  /// left running it billed a locked phone as reading time and pushed the
  /// inflated total to Supabase every 30 s.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _localFile == null) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _sessionNotifier.pause();
      case AppLifecycleState.resumed:
        _sessionNotifier.start();
      default:
        break;
    }
  }

  // ── PDF Download ──────────────────────────

  Future<void> _startDownload() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _downloadProgress = 0.0;
      _localFile = null;
    });

    // Close any existing stream
    await _progressCtrl?.close();
    _progressCtrl = StreamController<double>.broadcast();

    _progressCtrl!.stream.listen((progress) {
      if (mounted) setState(() => _downloadProgress = progress);
    });

    try {
      final file = await PdfDownloadService.getOrDownload(
        widget.book.pdfUrl!,
        progressController: _progressCtrl,
      );
      if (mounted) {
        setState(() {
          _localFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── UI helpers ────────────────────────────

  /// Pointer events are observed rather than claimed, so a tap has to be
  /// rebuilt from its down/up pair: everything else the viewer does with a
  /// finger — flicking through pages, long-pressing to select, pinching to
  /// zoom — moves, holds, or arrives as two pointers.
  void _trackTapDown(PointerDownEvent event) {
    if (++_pointers > 1) {
      _tapDownPos = null;
      return;
    }
    _tapDownPos = event.position;
    _tapDownTime = event.timeStamp;
  }

  void _trackTapUp(PointerUpEvent event) {
    if (_pointers > 0) _pointers--;
    final downPos = _tapDownPos;
    final downTime = _tapDownTime;
    _tapDownPos = null;
    _tapDownTime = null;
    if (downPos == null || downTime == null) return;
    if ((event.position - downPos).distance > 20) return;
    if (event.timeStamp - downTime > const Duration(milliseconds: 300)) return;
    // Double-tap zoom arrives as two ups a few ms apart; honouring both would
    // flash the chrome off and back on.
    final lastUp = _lastTapUpTime;
    if (lastUp != null &&
        event.timeStamp - lastUp < const Duration(milliseconds: 400)) {
      return;
    }
    _lastTapUpTime = event.timeStamp;
    if (_isTextSelected) {
      _clearSelection();
    } else {
      _toggleUI();
    }
  }

  void _dropTap(PointerCancelEvent event) {
    if (_pointers > 0) _pointers--;
    _tapDownPos = null;
    _tapDownTime = null;
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      _uiAnim.forward();
    } else {
      _uiAnim.reverse();
    }
  }

  void _clearSelection() {
    // Runs on every page change; without this guard each scroll step rebuilt
    // the whole viewer for a selection that was never there.
    if (!_isTextSelected && _selectedText.isEmpty) return;
    _pdfController.clearSelection();
    if (!mounted) return;
    setState(() {
      _isTextSelected = false;
      _selectedText = '';
    });
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final accentColor = widget.book.accentColor;
    final session = ref.watch(pdfSessionProvider(_bookId));

    // No PDF URL fallback
    if (widget.book.pdfUrl == null) {
      return Scaffold(
        backgroundColor: colors.background,
        // AppBarWidget instead of a plain AppBar — consistent with the
        // rest of the app's app bars (audit item 29). Its default
        // headingMedium style already renders in Amiri for Arabic, so the
        // explicit fontFamily override here was redundant.
        appBar: AppBarWidget(
          leading: const CustomLeadingButton(),
          title: widget.book.titleAr,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textDim),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.bookPdfNoUrlError,
                style: typography.bodyMedium,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // ── PDF Viewer / Loading / Error ──
          if (_error != null)
            _buildErrorView()
          else if (_isLoading || _localFile == null)
            _buildLoadingView(accentColor)
          else
            // Tap-to-toggle-UI. SfPdfViewer's page canvas registers its own
            // TapGestureRecognizer, and the innermost recognizer wins the
            // arena, so a GestureDetector wrapped around the viewer never
            // fires over page content. A Listener sits outside the arena and
            // still sees every pointer event, so the tap is reconstructed from
            // the down/up pair here — leaving selection, scrolling and pinch
            // zoom to the viewer.
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _trackTapDown,
              onPointerUp: _trackTapUp,
              onPointerCancel: _dropTap,
              child: SfPdfViewer.file(
                _localFile!,
                key: _pdfViewerKey,
                controller: _pdfController,

                // ── Smooth continuous scrolling ──────────────────────────
                scrollDirection: PdfScrollDirection.vertical,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                pageSpacing: 8,

                // ── Text selection ──────────────────────────────────────
                enableTextSelection: true,
                canShowTextSelectionMenu: false,

                // Misc viewer options
                canShowPageLoadingIndicator: true,
                // The page-number badge is chrome like the bars above and below
                // it, so it goes away with them instead of floating over the
                // page after a tap.
                canShowScrollHead: _showUI,
                enableDoubleTapZooming: true,

                onTextSelectionChanged:
                    (PdfTextSelectionChangedDetails details) {
                      final text = details.selectedText ?? '';
                      if (mounted) {
                        setState(() {
                          _selectedText = text;
                          _isTextSelected = text.isNotEmpty;
                        });
                      }
                    },
                onDocumentLoaded: (details) {
                  final total = details.document.pages.count;
                  Future.microtask(() {
                    if (!mounted) return;
                    _sessionNotifier.setTotal(total);
                    _sessionNotifier.start();
                  });

                  // Read the session live: `session` is this build's snapshot,
                  // written before the async loadSession() reply landed, so it
                  // could still say page 1 and drop the reader back to the
                  // start of a book they were halfway through.
                  final savedPage = ref
                      .read(pdfSessionProvider(_bookId))
                      .currentPage;
                  if (savedPage > 1 && savedPage <= total) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _pdfController.jumpToPage(savedPage);
                    });
                  }
                },
                onPageChanged: (details) {
                  _clearSelection();
                  _sessionNotifier.setPage(details.newPageNumber);
                },
                onDocumentLoadFailed: (details) {
                  if (!mounted) return;
                  setState(() {
                    _error = details.error;
                  });
                },
              ),
            ),

          // ── Top App Bar ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !_showUI,
                child: _buildTopBar(session, accentColor),
              ),
            ),
          ),

          // ── Bottom Progress Panel ───────
          if (!_isLoading && _localFile != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: (_showUI && !_isTextSelected) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: !_showUI || _isTextSelected,
                  child: _buildBottomPanel(session, accentColor),
                ),
              ),
            ),

          // ── Text Selection Action Bar ───
          if (!_isLoading && _localFile != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _isTextSelected ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _isTextSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !_isTextSelected,
                    child: _buildSelectionActionBar(accentColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────

  Widget _buildLoadingView(Color accentColor) {
    final l10n = AppLocalizations.of(context)!;
    final pct = (_downloadProgress * 100).toInt();
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: TakwaLoadingIndicator(color: accentColor)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _downloadProgress > 0
                  ? l10n.bookPdfDownloadingPercentLabel(pct)
                  : l10n.bookPdfDownloadingLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.orangeAccent,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.bookPdfLoadFailedTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8A96E),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                l10n.prayerScreenRetryButton,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PdfSessionState session, Color accentColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 18,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          const CustomLeadingButton(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.book.titleAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.book.authorAr,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(PdfSessionState session, Color accentColor) {
    final total = session.totalPages;
    final page = session.currentPage;
    final progress = session.progressFraction;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reading progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              // Reading time
              _InfoChip(icon: Icons.timer_outlined, label: session.timerLabel),
              const SizedBox(width: AppSpacing.sm),

              // Page slider
              Expanded(
                child: total > 1
                    ? SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          trackHeight: 3,
                          activeTrackColor: accentColor,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: accentColor,
                          overlayColor: accentColor.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          min: 1,
                          max: total.toDouble(),
                          value: page.clamp(1, total).toDouble(),
                          onChanged: (v) {
                            _sessionNotifier.setPage(v.round());
                          },
                          onChangeEnd: (v) {
                            _pdfController.jumpToPage(v.round());
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Page counter chip
              _InfoChip(
                icon: Icons.menu_book_rounded,
                label: total > 0 ? '$page / $total' : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom action bar that appears when text is selected.
  /// Offers Share, Underline-highlight copy, and Bookmark actions.
  Widget _buildSelectionActionBar(Color accentColor) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.70),
          ],
        ),
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Share
          _SelectionActionButton(
            icon: Icons.share_rounded,
            label: l10n.bookPdfShareAction,
            accentColor: accentColor,
            onTap: () {
              if (_selectedText.isNotEmpty) {
                SharePlus.instance.share(
                  ShareParams(text: _selectedText),
                );
              }
              _clearSelection();
            },
          ),

          // Copy
          _SelectionActionButton(
            icon: Icons.copy_rounded,
            label: l10n.adhkarCopyTooltip,
            accentColor: accentColor,
            onTap: () {
              if (_selectedText.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: _selectedText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.bookPdfCopiedToast,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Amiri'),
                    ),
                    backgroundColor: accentColor,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                );
              }
              _clearSelection();
            },
          ),

          // Highlight (visual underline feedback)
          _SelectionActionButton(
            icon: Icons.format_underline_rounded,
            label: l10n.bookPdfHighlightAction,
            accentColor: accentColor,
            onTap: () {
              // Syncfusion's addAnnotation API or simply copy with visual cue
              if (_selectedText.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.bookPdfHighlightedToast,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Amiri'),
                    ),
                    backgroundColor: Colors.amber.shade700,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                );
              }
              _clearSelection();
            },
          ),

          // Dismiss
          _SelectionActionButton(
            icon: Icons.close_rounded,
            label: l10n.commonCancel,
            accentColor: Colors.white54,
            onTap: _clearSelection,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SMALL WIDGETS
// ─────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
