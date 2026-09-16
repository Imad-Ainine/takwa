import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:takwa/core/providers/adhkar_providers.dart';

class MisbahaState {
  final int count;
  final bool isListening;
  final bool isAvailable;
  final bool isSpeaking;
  final DhikrItem? selectedDhikr;

  MisbahaState({
    this.count = 0,
    this.isListening = false,
    this.isAvailable = false,
    this.isSpeaking = false,
    this.selectedDhikr,
  });

  MisbahaState copyWith({
    int? count,
    bool? isListening,
    bool? isAvailable,
    bool? isSpeaking,
    DhikrItem? selectedDhikr,
    bool clearSelectedDhikr = false,
  }) {
    return MisbahaState(
      count: count ?? this.count,
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      selectedDhikr: clearSelectedDhikr
          ? null
          : (selectedDhikr ?? this.selectedDhikr),
    );
  }
}

class MisbahaNotifier extends Notifier<MisbahaState> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  String _lastRecognizedWords = '';
  DateTime _lastIncrementTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  MisbahaState build() {
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initSpeech();
    _initTts();
    return MisbahaState();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ar-SA");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(0.8);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });

    _tts.setCancelHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
  }

  void selectDhikr(DhikrItem item) {
    // Also stop speaking if currently speaking
    if (state.isSpeaking) _tts.stop();
    state = state.copyWith(selectedDhikr: item, count: 0, isSpeaking: false);
  }

  void clearDhikr() {
    if (state.isSpeaking) _tts.stop();
    state = state.copyWith(
      clearSelectedDhikr: true,
      count: 0,
      isSpeaking: false,
    );
  }

  Future<void> speakDhikr() async {
    if (state.selectedDhikr == null) return;

    if (state.isSpeaking) {
      await _tts.stop();
      state = state.copyWith(isSpeaking: false);
    } else {
      state = state.copyWith(isSpeaking: true);
      await _tts.speak(state.selectedDhikr!.arabic);
    }
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (state.isListening && state.isAvailable) {
            _startListening();
          } else {
            state = state.copyWith(isListening: false);
          }
        }
      },
      onError: (val) {
        if (state.isListening && state.isAvailable) {
          _startListening();
        } else {
          state = state.copyWith(isListening: false);
        }
      },
    );
    state = state.copyWith(isAvailable: available);
  }

  void increment() {
    int newCount = state.count + 1;

    // Check if target is reached
    if (state.selectedDhikr != null && newCount >= state.selectedDhikr!.count) {
      state = state.copyWith(count: state.selectedDhikr!.count);
      // Heavy vibration on completion
      HapticFeedback.heavyImpact();
      Future.delayed(
        const Duration(milliseconds: 300),
        () => HapticFeedback.heavyImpact(),
      );
    } else {
      state = state.copyWith(count: newCount);
      // Light feedback on increment
      HapticFeedback.lightImpact();
    }
  }

  void reset() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(count: 0);
  }

  Future<void> listen(bool start) async {
    if (start) {
      if (!state.isAvailable) {
        await _initSpeech();
        if (!state.isAvailable) return;
      }
      if (!state.isListening) {
        state = state.copyWith(isListening: true);
        _lastRecognizedWords = '';
        await _startListening();
      }
    } else {
      if (state.isListening) {
        state = state.copyWith(isListening: false);
        await _speech.stop();
      }
    }
  }

  String _normalizeArabic(String text) {
    if (text.isEmpty) return '';

    // Remove diacritics (Tashkeel)
    final diacritics = RegExp(r'[\u064B-\u065F\u0670]');
    String result = text.replaceAll(diacritics, '');

    // Normalize Alif
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Normalize Teh Marbuta to Heh (common in speech recognition)
    result = result.replaceAll('ة', 'ه');
    // Normalize Yeh/Alef Maksura
    result = result.replaceAll('ى', 'ي');

    // Normalize Hamzas
    result = result.replaceAll('ؤ', 'و');
    result = result.replaceAll('ئ', 'ي');
    result = result.replaceAll('ء', '');

    // Remove extra spaces and punctuation
    // Keep only Arabic letters and spaces
    result = result.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '');

    // Normalize multiple spaces into one
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    return result.trim().toLowerCase();
  }

  Future<void> _startListening() async {
    if (!state.isListening) return;

    _lastRecognizedWords = '';
    int lastWordCount = 0;
    int lastTargetMatches = 0;

    try {
      await _speech.listen(
        onResult: (val) {
          final words = val.recognizedWords.trim();
          if (words.isEmpty) return;

          // Detect engine reset (if the recognized text significantly shrinks)
          if (words.length < _lastRecognizedWords.length * 0.5 &&
              _lastRecognizedWords.isNotEmpty) {
            lastWordCount = 0;
            lastTargetMatches = 0;
            _lastRecognizedWords = '';
          }

          if (state.selectedDhikr != null) {
            // Specific Dhikr mode: Compare normalized strings WITHOUT spaces for max robustness
            final normalizedTarget = _normalizeArabic(
              state.selectedDhikr!.arabic,
            ).replaceAll(' ', '');
            final normalizedWords = _normalizeArabic(words).replaceAll(' ', '');

            final currentMatches = _countOccurrences(
              normalizedWords,
              normalizedTarget,
            );

            if (currentMatches > lastTargetMatches) {
              final now = DateTime.now();
              if (now.difference(_lastIncrementTime).inMilliseconds > 350) {
                // Increment for each NEW match found in the current string
                for (int i = 0; i < (currentMatches - lastTargetMatches); i++) {
                  increment();
                }
                lastTargetMatches = currentMatches;
                _lastIncrementTime = now;
              }
            }
          } else {
            // Any Word mode: Simple word counting
            final currentWordsList = words
                .split(RegExp(r'\s+'))
                .where((w) => w.length > 1)
                .toList();
            final currentWordCount = currentWordsList.length;

            if (currentWordCount > lastWordCount) {
              final now = DateTime.now();
              if (now.difference(_lastIncrementTime).inMilliseconds > 350) {
                for (int i = 0; i < (currentWordCount - lastWordCount); i++) {
                  increment();
                }
                lastWordCount = currentWordCount;
                _lastIncrementTime = now;
              }
            }
          }

          _lastRecognizedWords = words;
        },
        listenOptions: stt.SpeechListenOptions(
          // Ensure Arabic Saudi Arabia locale
          localeId: 'ar-SA',
          cancelOnError: false,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      state = state.copyWith(isListening: false);
    }
  }

  int _countOccurrences(String text, String target) {
    if (target.isEmpty) return 0;
    int count = 0;
    int index = 0;
    while ((index = text.indexOf(target, index)) != -1) {
      count++;
      index += target.length;
    }
    return count;
  }
}

final misbahaProvider = NotifierProvider<MisbahaNotifier, MisbahaState>(() {
  return MisbahaNotifier();
});
