import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'services/push_notifications_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_scope.dart';
import 'theme/theme_controller.dart';
import 'widgets/toast/toast_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationsService.initialize();
  final themeController = ThemeController();
  await themeController.load();
  runApp(ProSaccoMobileApp(themeController: themeController));
}

/// Root app — light/dark themes from [AppTheme] + persisted [ThemeMode].
class ProSaccoMobileApp extends StatelessWidget {
  const ProSaccoMobileApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: PushNotificationsService.navigatorKey,
          title: 'ProSacco',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.mode,
          builder: (context, child) {
            return AppThemeScope(
              notifier: themeController,
              child: ToastServiceScope(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const AppBootstrap(),
        );
      },
    );
  }
}
