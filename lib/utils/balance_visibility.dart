import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide balance show/hide preference (one eye toggles all balances).
class BalanceVisibilityController extends ChangeNotifier {
  BalanceVisibilityController._(this._visible);

  static const String _prefKey = 'prosacco_balances_visible';

  bool _visible;

  bool get visible => _visible;

  void toggle() {
    _visible = !_visible;
    notifyListeners();
    SharedPreferences.getInstance().then((sp) => sp.setBool(_prefKey, _visible));
  }

  void setVisible(bool value) {
    if (_visible == value) return;
    _visible = value;
    notifyListeners();
    SharedPreferences.getInstance().then((sp) => sp.setBool(_prefKey, value));
  }

  String formatAmount(String formatted, {String hidden = '••••••'}) {
    return _visible ? formatted : hidden;
  }

  static Future<BalanceVisibilityController> load() async {
    final sp = await SharedPreferences.getInstance();
    final visible = sp.getBool(_prefKey) ?? false;
    return BalanceVisibilityController._(visible);
  }
}

class BalanceVisibilityScope extends InheritedNotifier<BalanceVisibilityController> {
  const BalanceVisibilityScope({
    super.key,
    required BalanceVisibilityController controller,
    required super.child,
  }) : super(notifier: controller);

  static BalanceVisibilityController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BalanceVisibilityScope>();
    assert(scope != null, 'BalanceVisibilityScope not found in context');
    return scope!.notifier!;
  }

  static BalanceVisibilityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BalanceVisibilityScope>()
        ?.notifier;
  }
}
