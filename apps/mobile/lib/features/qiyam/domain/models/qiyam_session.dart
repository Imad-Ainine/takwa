import 'package:flutter/material.dart';
import 'package:takwa/l10n/app_localizations.dart';

enum QiyamStageStatus { idle, running, paused, completed }

/// Localized title/subtitle for a [QiyamStage], keyed by its stable [id].
/// The stage list itself is a `const` default constructor argument (built
/// before any [BuildContext] exists), so display text can't live on the
/// model directly — it's looked up here at render time instead, the same
/// pattern as `prayerLocalizedName`.
String qiyamStageTitle(AppLocalizations l10n, String id) => switch (id) {
  'istighfar' => l10n.qiyamStageIstighfarTitle,
  'dua' => l10n.qiyamStageDuaTitle,
  'salah' => l10n.qiyamStageSalahTitle,
  'witr' => l10n.qiyamStageWitrTitle,
  _ => id,
};

String qiyamStageSubtitle(AppLocalizations l10n, String id) => switch (id) {
  'istighfar' => l10n.qiyamStageIstighfarSubtitle,
  'dua' => l10n.qiyamStageDuaSubtitle,
  'salah' => l10n.qiyamStageSalahSubtitle,
  'witr' => l10n.qiyamStageWitrSubtitle,
  _ => '',
};

class QiyamStage {
  final String id;
  final String emoji;
  final Duration defaultDuration;
  final Color color;

  const QiyamStage({
    required this.id,
    required this.emoji,
    required this.defaultDuration,
    required this.color,
  });

  QiyamStage copyWith({
    String? id,
    String? emoji,
    Duration? defaultDuration,
    Color? color,
  }) {
    return QiyamStage(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      color: color ?? this.color,
    );
  }
}

class QiyamSessionState {
  final int currentStageIndex;
  final QiyamStageStatus status;
  final Duration elapsed;
  final List<QiyamStage> stages;

  const QiyamSessionState({
    this.currentStageIndex = 0,
    this.status = QiyamStageStatus.idle,
    this.elapsed = Duration.zero,
    this.stages = const [
      QiyamStage(
        id: 'istighfar',
        emoji: '📿',
        defaultDuration: Duration(minutes: 5),
        color: Color(0xFFB8860B), // Dark Gold
      ),
      QiyamStage(
        id: 'dua',
        emoji: '🤲',
        defaultDuration: Duration(minutes: 10),
        color: Color(0xFFD4AF37), // Metallic Gold
      ),
      QiyamStage(
        id: 'salah',
        emoji: '🕌',
        defaultDuration: Duration(minutes: 20),
        color: Color(0xFFA67C00), // Deep Gold
      ),
      QiyamStage(
        id: 'witr',
        emoji: '✨',
        defaultDuration: Duration(minutes: 5),
        color: Color(0xFFFFD700), // Vivid Gold
      ),
    ],
  });

  QiyamStage get currentStage => stages[currentStageIndex];

  QiyamSessionState copyWith({
    int? currentStageIndex,
    QiyamStageStatus? status,
    Duration? elapsed,
    List<QiyamStage>? stages,
  }) {
    return QiyamSessionState(
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      stages: stages ?? this.stages,
    );
  }
}
