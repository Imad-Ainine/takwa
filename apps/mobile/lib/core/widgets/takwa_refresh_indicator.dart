import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:takwa/core/theme/app_theme.dart';

class TakwaRefreshIndicator extends StatefulWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final Color? color;
  final double displacement;

  const TakwaRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.displacement = 100.0,
  });

  @override
  State<TakwaRefreshIndicator> createState() => _TakwaRefreshIndicatorState();
}

class _TakwaRefreshIndicatorState extends State<TakwaRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoColor = widget.color ?? context.colors.gold;
    const containerSize = 56.0;

    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      offsetToArmed: widget.displacement,
      onStateChanged: (IndicatorStateChange state) {
        if (state.currentState == IndicatorState.loading) {
          _spinController.repeat();
        } else if (state.currentState == IndicatorState.idle) {
          _spinController.stop();
          _spinController.reset();
        }
      },
      builder: (BuildContext context, Widget child, IndicatorController controller) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            // The scrollable child is smoothly pushed down via translation
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                // Determine how much to shift the list view
                final dy = controller.value * widget.displacement;
                return Transform.translate(offset: Offset(0, dy), child: child);
              },
            ),

            // Custom Takwa Animated Logo
            AnimatedBuilder(
              animation: Listenable.merge([controller, _spinController]),
              builder: (context, _) {
                final isArmedOrLoading =
                    controller.isArmed ||
                    controller.isLoading ||
                    controller.isComplete;

                // Opacity fades in over the first half of the pull
                final opacity = (controller.value * 2).clamp(0.0, 1.0);

                // Start from -56 (hidden), pull down until displacement height offset
                final topOffset =
                    -containerSize +
                    (controller.value * widget.displacement * 1.2);

                // Rotations: Half a turn while pulling, continuous spin while loading
                final rotation = controller.isLoading
                    ? _spinController.value * 2 * math.pi
                    : controller.value * math.pi;

                // Slight popping scale when armed
                final scale = isArmedOrLoading
                    ? 1.05
                    : (controller.value).clamp(0.0, 1.0);

                return Positioned(
                  top: topOffset.clamp(
                    -containerSize,
                    widget.displacement * 0.5,
                  ),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: rotation,
                        child: Container(
                          width: containerSize,
                          height: containerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.card,
                            boxShadow: [
                              BoxShadow(
                                color: logoColor.withValues(alpha: isArmedOrLoading ? 0.35 : 0.15),
                                blurRadius: isArmedOrLoading ? 25 : 10,
                                spreadRadius: isArmedOrLoading ? 2 : 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: logoColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 34,
                              height: 34,
                              color: logoColor,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
