// Feature: login-toast-notifications, Property 5
// **Validates: Requirements 3.2**

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
  group('Property 5 – error toast message contains the error string', () {
    testWidgets('100 random error strings appear in the toast',
        (WidgetTester tester) async {
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        final errorString = _randomString(rng, 40);

        await tester.pumpWidget(_buildTestApp(
          child: Builder(builder: (context) {
            return Scaffold(
              body: GestureDetector(
                onTap: () {
                  ToastService.of(context).show(
                    variant: ToastVariant.error,
                    message: errorString,
                  );
                },
                child: const Text('showError'),
              ),
            );
          }),
        ));

        await tester.tap(find.text('showError'));
        await tester.pumpAndSettle();

        expect(find.text(errorString), findsOneWidget,
            reason: 'Toast should contain error string "$errorString" (iteration $i)');

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });
  });
}
