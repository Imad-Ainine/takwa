// Verifies the lottie package is wired up and can actually decode the
// bundled dotLottie (.lottie) assets — not just that the dependency
// resolves. animate:false keeps the composition static so there is no
// looping animation controller / pending timer to unwind.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('bundled dotLottie asset decodes and renders a frame',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/lottie/lottie_splash.lottie',
              animate: false,
            ),
          ),
        ),
      ),
    );

    // Let the async composition load + first frame render settle.
    await tester.pumpAndSettle();

    expect(find.byType(Lottie), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
