import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';
import '../domain/models/qiyam_session.dart';

class QiyamNotifier extends StateNotifier<QiyamSessionState> {
  QiyamNotifier() : super(const QiyamSessionState());

  Timer? _timer;

  void startSession() {
    state = state.copyWith(status: QiyamStageStatus.running);
    _startTimer();
  }

  void pauseSession() {
    state = state.copyWith(status: QiyamStageStatus.paused);
    _timer?.cancel();
  }

  void resetSession() {
    _timer?.cancel();
    state = const QiyamSessionState();
  }

  void nextStage() {
    if (state.currentStageIndex < state.stages.length - 1) {
      state = state.copyWith(
        currentStageIndex: state.currentStageIndex + 1,
        elapsed: Duration.zero,
      );
    } else {
      state = state.copyWith(status: QiyamStageStatus.completed);
      _timer?.cancel();
    }
  }

  void previousStage() {
    if (state.currentStageIndex > 0) {
      state = state.copyWith(
        currentStageIndex: state.currentStageIndex - 1,
        elapsed: Duration.zero,
      );
    }
  }

  void updatePlanDuration(Duration duration) {
    _timer?.cancel();
    final updatedStages = state.stages
        .map((s) => s.copyWith(defaultDuration: duration))
        .toList();
    state = state.copyWith(
      stages: updatedStages,
      elapsed: Duration.zero,
      status: QiyamStageStatus.idle,
      currentStageIndex: 0,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );

      if (state.elapsed >= state.currentStage.defaultDuration) {
        // Auto-advance or wait for user? Let's stay in current stage but marked as done
        // For now, let's just keep counting up or wait for next.
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final qiyamSessionProvider =
    StateNotifierProvider<QiyamNotifier, QiyamSessionState>((ref) {
      return QiyamNotifier();
    });

// ── Qiyam Onboarding Provider ──
final qiyamOnboardingDoneProvider = FutureProvider<bool>((ref) async {
  final v = await ref.watch(settingsDaoProvider).get('qiyamOnboardingDone');
  return v == 'true';
});

final completeQiyamOnboardingProvider = Provider((ref) {
  return () async {
    await ref.read(settingsDaoProvider).set('qiyamOnboardingDone', 'true');
    ref.invalidate(qiyamOnboardingDoneProvider);
  };
});
