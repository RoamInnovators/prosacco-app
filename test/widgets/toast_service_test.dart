import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosacco_mobile/theme/prosacco_palette.dart';
import 'package:prosacco_mobile/widgets/toast/toast_service.dart';
import 'package:prosacco_mobile/widgets/toast/toast_variant.dart';

/// Builds a test app with [ToastServiceScope] placed inside the route so that
/// the navigator's [Overlay] is available to [Overlay.of] calls in the service.
Widget buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const [ProsaccoPalette.light],
    ),
    home: ToastServiceScope(child: child),
  );
}

/// A helper widget that triggers a toast when tapped.
class ToastTrigger extends StatelessWidget {
  const ToastTrigger({
    super.key,
    required this.message,
    required this.variant,
  });

  final String message;
  final ToastVariant variant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          ToastService.of(context).show(
            message: message,
            variant: variant,
          );
        },
        child: const Text('trigger'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers for random generation (property-based tests)
// ---------------------------------------------------------------------------

String _randomString(Random rng, int maxLen) {
  final len = rng.nextInt(maxLen) + 1;
  return String.fromCharCodes(
    List.generate(len, (_) => rng.nextInt(26) + 97), // a-z
  );
}

ToastVariant _randomVariant(Random rng) {
  return ToastVariant.values[rng.nextInt(ToastVariant.values.length)];
}

void main() {
  // =========================================================================
  // Unit Tests (Task 9)
  // =========================================================================

  group('ToastVariant enum', () {
    test('has exactly 4 values', () {
      expect(ToastVariant.values.length, 4);
    });

    test('contains success, error, warning, info', () {
      expect(
        ToastVariant.values,
        containsAll([
          ToastVariant.success,
          ToastVariant.error,
          ToastVariant.warning,
          ToastVariant.info,
        ]),
      );
    });
  });

  group('Dismiss button removes toast', () {
    testWidgets('tapping dismiss removes the toast from the widget tree',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const ToastTrigger(
          message: 'Dismissable toast',
          variant: ToastVariant.info,
        ),
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Dismissable toast'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Dismissable toast'), findsNothing);
    });
  });

  group('Empty-credentials error toast', () {
    testWidgets('renders error toast with correct message and icon',
        (WidgetTester tester) async {
      const msg = 'Enter your email or member number and password.';
      await tester.pumpWidget(buildTestApp(
        child: const ToastTrigger(message: msg, variant: ToastVariant.error),
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text(msg), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('Lockout warning toast', () {
    testWidgets('renders warning toast with correct message and icon',
        (WidgetTester tester) async {
      const msg =
          'Account locked for 15 minutes due to too many failed attempts.';
      await tester.pumpWidget(buildTestApp(
        child: const ToastTrigger(message: msg, variant: ToastVariant.warning),
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text(msg), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('Incomplete OTP error toast', () {
    testWidgets('renders error toast with incomplete OTP message',
        (WidgetTester tester) async {
      const msg = 'Enter the full 6-digit code.';
      await tester.pumpWidget(buildTestApp(
        child: const ToastTrigger(message: msg, variant: ToastVariant.error),
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text(msg), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('Resend success info toast', () {
    testWidgets('renders info toast with resend confirmation message',
        (WidgetTester tester) async {
      const msg = 'A new code has been sent.';
      await tester.pumpWidget(buildTestApp(
        child: const ToastTrigger(message: msg, variant: ToastVariant.info),
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text(msg), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('Semantics / accessibility', () {
    testWidgets('toast has Semantics widget with variant name and message',
        (WidgetTester tester) async {
      const msg = 'Welcome, John!';
      await tester.pumpWidget(buildTestApp(
        child: const ToastTrigger(
          message: msg,
          variant: ToastVariant.success,
        ),
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'success: Welcome, John!',
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });

  // =========================================================================
  // Property-Based Tests (Task 10) — manual loop approach using dart:math
  // =========================================================================

  // Feature: login-toast-notifications, Property 1
  // **Validates: Requirements 2.1**
  group('Property 1 – random message/variant renders Icon, Text, dismiss', () {
    testWidgets('100 random combos contain Icon, message Text, and dismiss IconButton',
        (WidgetTester tester) async {
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        final msg = _randomString(rng, 30);
        final variant = _randomVariant(rng);

        await tester.pumpWidget(buildTestApp(
          child: ToastTrigger(message: msg, variant: variant),
        ));

        await tester.tap(find.text('trigger'));
        await tester.pumpAndSettle();

        expect(find.byType(Icon), findsWidgets);
        expect(find.text(msg), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });
  });

  // Feature: login-toast-notifications, Property 2
  // **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
  group('Property 2 – each variant has correct IconData and color palette', () {
    final variantExpectations = <ToastVariant, IconData>{
      ToastVariant.success: Icons.check_circle_outline,
      ToastVariant.error: Icons.error_outline,
      ToastVariant.warning: Icons.warning_amber_rounded,
      ToastVariant.info: Icons.info_outline,
    };

    for (final variant in ToastVariant.values) {
      testWidgets('variant ${variant.name} shows correct icon and colors',
          (WidgetTester tester) async {
        const msg = 'property2 test message';
        await tester.pumpWidget(buildTestApp(
          child: ToastTrigger(message: msg, variant: variant),
        ));

        await tester.tap(find.text('trigger'));
        await tester.pumpAndSettle();

        expect(find.byIcon(variantExpectations[variant]!), findsOneWidget);

        final iconFinder = find.byIcon(variantExpectations[variant]!);
        final iconWidget = tester.widget<Icon>(iconFinder);

        const pal = ProsaccoPalette.light;
        late Color expectedIconColor;
        late Color expectedBackground;

        switch (variant) {
          case ToastVariant.success:
            expectedIconColor = pal.success;
            expectedBackground = pal.success.withValues(alpha: 0.12);
          case ToastVariant.error:
            expectedIconColor = pal.error;
            expectedBackground = pal.errorContainer;
          case ToastVariant.warning:
            expectedIconColor = const Color(0xFFF57F17);
            expectedBackground = const Color(0xFFFFF8E1);
          case ToastVariant.info:
            expectedIconColor = pal.primaryContainer;
            expectedBackground = pal.primaryContainer.withValues(alpha: 0.12);
        }

        expect(iconWidget.color, equals(expectedIconColor));

        // Verify background via the toast's Material widget.
        // Find the Material that is a direct child of the toast's Semantics node.
        final semanticsLabel = '${variant.name}: $msg';
        final toastSemantics = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == semanticsLabel,
        );
        final toastMaterialFinder = find.descendant(
          of: toastSemantics,
          matching: find.byType(Material),
        );
        // Take the first Material (the toast card itself, not nested ones from IconButton).
        final toastMaterial = tester.widgetList<Material>(toastMaterialFinder).first;
        expect(toastMaterial.color, equals(expectedBackground));

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      });
    }
  });

  // Feature: login-toast-notifications, Property 3
  // **Validates: Requirements 1.5**
  group('Property 3 – default durations match spec (3s success/info, 4s error/warning)', () {
    test('success and info default to 3 seconds', () {
      for (final variant in [ToastVariant.success, ToastVariant.info]) {
        final request = ToastRequest(message: 'test', variant: variant);
        expect(request.duration, const Duration(seconds: 3),
            reason: '${variant.name} should default to 3s');
      }
    });

    test('error and warning default to 4 seconds', () {
      for (final variant in [ToastVariant.error, ToastVariant.warning]) {
        final request = ToastRequest(message: 'test', variant: variant);
        expect(request.duration, const Duration(seconds: 4),
            reason: '${variant.name} should default to 4s');
      }
    });

    test('explicit duration overrides default for all 100 random variants', () {
      final rng = Random(42);
      for (var i = 0; i < 100; i++) {
        final variant = _randomVariant(rng);
        final customMs = rng.nextInt(10000) + 500;
        final customDuration = Duration(milliseconds: customMs);
        final request = ToastRequest(
          message: 'test',
          variant: variant,
          duration: customDuration,
        );
        expect(request.duration, customDuration,
            reason: 'explicit duration should override default');
      }
    });
  });

  // Feature: login-toast-notifications, Property 4
  // **Validates: Requirements 1.4**
  group('Property 4 – FIFO display order for queued toasts', () {
    testWidgets('100 random lists verify FIFO order',
        (WidgetTester tester) async {
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        final count = rng.nextInt(4) + 2; // 2-5 toasts per iteration
        final messages = List.generate(count, (j) => 'fifo_${i}_$j');
        final variants = List.generate(count, (_) => _randomVariant(rng));

        await tester.pumpWidget(buildTestApp(
          child: Builder(builder: (context) {
            return Scaffold(
              body: GestureDetector(
                onTap: () {
                  final svc = ToastService.of(context);
                  for (var j = 0; j < count; j++) {
                    svc.show(message: messages[j], variant: variants[j]);
                  }
                },
                child: const Text('enqueue'),
              ),
            );
          }),
        ));

        await tester.tap(find.text('enqueue'));
        await tester.pumpAndSettle();

        for (var j = 0; j < count; j++) {
          expect(find.text(messages[j]), findsOneWidget,
              reason: 'Toast $j should be visible (iteration $i)');

          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
        }
      }
    });
  });

  // Feature: login-toast-notifications, Property 7
  // **Validates: Requirements 3.4**
  group('Property 7 – at most one toast visible at a time on SignInGate', () {
    testWidgets('random sequences of error toasts show at most one at a time',
        (WidgetTester tester) async {
      final rng = Random(42);

      for (var i = 0; i < 20; i++) {
        final count = rng.nextInt(5) + 2; // 2-6 toasts
        final messages = List.generate(count, (j) => 'err_${i}_$j');

        await tester.pumpWidget(buildTestApp(
          child: Builder(builder: (context) {
            return Scaffold(
              body: GestureDetector(
                onTap: () {
                  final svc = ToastService.of(context);
                  for (var j = 0; j < count; j++) {
                    svc.dismiss();
                    svc.show(
                      message: messages[j],
                      variant: ToastVariant.error,
                    );
                  }
                },
                child: const Text('fire'),
              ),
            );
          }),
        ));

        await tester.tap(find.text('fire'));
        await tester.pumpAndSettle();

        final visibleToasts = messages
            .where((m) => find.text(m).evaluate().isNotEmpty)
            .toList();
        expect(visibleToasts.length, lessThanOrEqualTo(1),
            reason: 'At most one toast visible at a time (iteration $i)');

        if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
        }
      }
    });
  });

  // Feature: login-toast-notifications, Property 8
  // **Validates: Requirements 6.1**
  group('Property 8 – Semantics label contains variant name and message', () {
    testWidgets('100 random variant/message combos have correct Semantics label',
        (WidgetTester tester) async {
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        final msg = _randomString(rng, 30);
        final variant = _randomVariant(rng);

        await tester.pumpWidget(buildTestApp(
          child: ToastTrigger(message: msg, variant: variant),
        ));

        await tester.tap(find.text('trigger'));
        await tester.pumpAndSettle();

        final expectedLabel = '${variant.name}: $msg';
        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == expectedLabel,
        );
        expect(semanticsFinder, findsOneWidget,
            reason: 'Semantics label should be "$expectedLabel" (iteration $i)');

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });
  });
}
