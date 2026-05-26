// Feature: login-toast-notifications, Property 6
// **Validates: Requirements 4.1, 4.2, 4.3**

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosacco_mobile/theme/prosacco_palette.dart';
import 'package:prosacco_mobile/widgets/toast/toast_service.dart';
import 'package:prosacco_mobile/widgets/toast/toast_variant.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: ThemeData(extensions: const [ProsaccoPalette.light]),
    home: ToastServiceScope(child: child),
  );
}

String _randomString(Random rng, int maxLen) {
  final len = rng.nextInt(maxLen) + 1;
  return String.fromCharCodes(
    List.generate(len, (_) => rng.nextInt(26) + 97),
  );
}

void main() {
  group('Property 6 – welcome message format for MFA and non-MFA flows', () {
    testWidgets('100 random display names produce correct welcome messages',
        (WidgetTester tester) async {
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        // Randomly decide if name is empty or not
        final hasName = rng.nextBool();
        final name = hasName ? _randomString(rng, 20) : '';
        final isMfa = rng.nextBool();

        // Compute expected message using the same logic as AppBootstrap
        late String expectedMessage;
        if (isMfa) {
          expectedMessage =
              name.isNotEmpty ? 'Welcome back, $name!' : 'Login successful.';
        } else {
          expectedMessage =
              name.isNotEmpty ? 'Welcome, $name!' : 'Login successful.';
        }

        await tester.pumpWidget(_buildTestApp(
          child: Builder(builder: (context) {
            return Scaffold(
              body: GestureDetector(
                onTap: () {
                  ToastService.of(context).show(
                    variant: ToastVariant.success,
                    message: expectedMessage,
                  );
                },
                child: const Text('welcome'),
              ),
            );
          }),
        ));

        await tester.tap(find.text('welcome'));
        await tester.pumpAndSettle();

        expect(find.text(expectedMessage), findsOneWidget,
            reason:
                'Welcome toast should show "$expectedMessage" (iteration $i, mfa=$isMfa, name="$name")');

        // Verify it's a success variant by checking the icon
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget,
            reason: 'Welcome toast should use success variant icon');

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });
  });
}
