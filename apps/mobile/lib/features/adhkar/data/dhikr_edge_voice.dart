import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_tts/flutter_edge_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// The Misbaha's dhikr voice: Microsoft Edge's neural Arabic text-to-speech,
/// played through just_audio instead of the platform TTS engine.
///
/// `ar-SA-HamedNeural` is an adult male Standard-Arabian voice, and the dhikr
/// texts are written with full tashkeel, which it inflects correctly — that is
/// the whole reason for using it rather than the on-device engine, whose Arabic
/// male voice sounds robotic.
///
/// Synthesis is a network round trip (~1.7 s for a short phrase), so the audio
/// is cached on disk per phrase: [prime] starts that when a dhikr is *selected*
/// and [play] waits for it if the tap beats the download. Once cached, a phrase
/// plays instantly and works with no connection at all.
///
/// If synthesis can't be had — offline, or Microsoft changing the consumer
/// endpoint this unofficial wrapper depends on — [play] reports false and the
/// caller falls back to [flutter_tts] ([MisbahaNotifier.speakDhikr]), so the
/// sound button never goes silent.
class DhikrEdgeVoice {
  static const String _voice = 'ar-SA-HamedNeural';

  /// Slightly under the engine's natural pace: dhikr is recited measured, and
  /// this is the value the old 0.4 speech-rate was reaching for without the
  /// drawl.
  static const String _rate = '0.85';

  /// Edge pads the head of every clip — measured at 0.23-0.25 s for the dhikr
  /// texts at this rate — which on a tap-to-play button reads as lag before
  /// the voice has even started. Clipped at load time instead of trimmed on
  /// disk, so the cached file stays exactly what the service returned.
  static const Duration _leadIn = Duration(milliseconds: 200);

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> _speaking = ValueNotifier(false);

  StreamSubscription<PlayerState>? _stateSub;
  FlutterEdgeTts? _tts;

  /// The phrase the in-flight or finished synthesis belongs to, and its file.
  String? _primedText;
  Future<String?>? _priming;
  String? _cachedPath;
  String? _loadedPath;
  bool _disposed = false;

  /// Whether the phrase that is currently primed has audio ready to play.
  bool get isReady => _cachedPath != null;

  /// Whether the recitation is playing.
  ValueListenable<bool> get speaking => _speaking;

  /// Starts fetching (or reuses the cached file for) [text]. Awaited by [play],
  /// which is how a tap that arrives mid-synthesis still gets the neural voice.
  Future<void> prime(String text) {
    if (_primedText == text && _priming != null) return _priming!.then((_) {});
    _primedText = text;
    _cachedPath = null;
    return _priming = _synthesize(text);
  }

  Future<String?> _synthesize(String text) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_cacheKey(text)}');
      if (await file.exists() && await file.length() > 0) {
        return _cachedPath = file.path;
      }
      final tts = _tts ??= FlutterEdgeTts(voice: _voice);
      await tts.synthesizeToFile(
        text,
        audioFilePath: file.path,
        prosody: const EdgeTtsProsody(rate: _rate),
      );
      if (!await file.exists() || await file.length() == 0) {
        // A half-written file would play as silence on every later tap.
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      return _cachedPath = file.path;
    } catch (e) {
      // Expected on a flight or in a dead zone; the TTS fallback covers it.
      developer.log('Edge dhikr synthesis failed: $e', name: 'DhikrEdgeVoice');
      return null;
    }
  }

  /// sha1 of voice+rate+text, so an edited dhikr text in a future release
  /// misses the cache instead of playing the old recording forever.
  String _cacheKey(String text) =>
      sha1.convert(utf8.encode('$_voice|$_rate|$text')).toString();

  Future<Directory> _cacheDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/dhikr_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Plays the primed phrase. Returns false when its audio isn't available, so
  /// the caller can fall back to speech synthesis.
  Future<bool> play() async {
    final text = _primedText;
    if (text == null) return false;
    final path = _cachedPath ?? await (_priming ??= _synthesize(text));
    if (path == null || _disposed) return false;
    try {
      // A new source per phrase, so a re-tap of the same dhikr just rewinds.
      // The clip drops the ~0.23 s of dead air Edge pads in front of every
      // synthesis; 200 ms is under the shortest one measured, so it can only
      // remove silence, never the first letter.
      if (_loadedPath != path) {
        await _player.setAudioSource(
          ClippingAudioSource(child: AudioSource.file(path), start: _leadIn),
        );
        _loadedPath = path;
      } else if (_player.processingState == ProcessingState.completed) {
        // just_audio's play() does not rewind a completed player.
        await _player.seek(Duration.zero);
      }
      _stateSub ??= _player.playerStateStream.listen((state) {
        if (_disposed) return;
        _speaking.value = state.playing;
      });
      await _player.play();
      return !_disposed;
    } catch (e) {
      developer.log('Edge dhikr playback failed: $e', name: 'DhikrEdgeVoice');
      _loadedPath = null;
      return false;
    }
  }

  Future<void> stop() async {
    if (_loadedPath == null) return;
    await _player.pause();
    await _player.seek(Duration.zero);
    _speaking.value = false;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _stateSub?.cancel();
    _stateSub = null;
    await _tts?.dispose();
    _tts = null;
    await _player.dispose();
    _speaking.dispose();
  }
}
