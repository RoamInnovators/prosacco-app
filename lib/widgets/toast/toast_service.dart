import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'toast_overlay_widget.dart';
import 'toast_variant.dart';

// ---------------------------------------------------------------------------
// ToastService – abstract interface
// ---------------------------------------------------------------------------

/// Centralized toast notification service accessible via [ToastService.of].
abstract class ToastService {
  /// Look up the nearest [ToastService] from the widget tree.
  static ToastService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ToastServiceInherited>();
    assert(scope != null, 'No ToastServiceScope found in the widget tree.');
    return scope!.controller;
  }

  /// Display a toast. [variant] controls color/icon. [duration] is optional
  /// (defaults: 3 s for success/info, 4 s for error/warning).
  void show({
    required String message,
    required ToastVariant variant,
    Duration? duration,
  });

  /// Remove the currently visible toast (if any) and clear the queue.
  void dismiss();
}

// ---------------------------------------------------------------------------
// ToastServiceScope – StatefulWidget host
// ---------------------------------------------------------------------------

/// Wraps a subtree and provides [ToastService.of] to all descendants.
///
/// Insert this inside `MaterialApp.builder` so that every route can display
/// toasts without depending on [ScaffoldMessenger].
class ToastServiceScope extends StatefulWidget {
  const ToastServiceScope({super.key, required this.child});

  final Widget child;

  @override
  State<ToastServiceScope> createState() => _ToastServiceScopeState();
}

class _ToastServiceScopeState extends State<ToastServiceScope> {
  late final _ToastController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _ToastController(this);
  }

  @override
  void dispose() {
    _controller._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ToastServiceInherited(
      controller: _controller,
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// _ToastServiceInherited – InheritedWidget plumbing
// ---------------------------------------------------------------------------

class _ToastServiceInherited extends InheritedWidget {
  const _ToastServiceInherited({
    required this.controller,
    required super.child,
  });

  final _ToastController controller;

  @override
  bool updateShouldNotify(_ToastServiceInherited oldWidget) =>
      controller != oldWidget.controller;
}

// ---------------------------------------------------------------------------
// _ToastController – FIFO queue + OverlayEntry management
// ---------------------------------------------------------------------------

/// Maximum number of queued (non-active) toast requests.
const int _kMaxQueueSize = 10;

class _ToastController implements ToastService {
  _ToastController(this._scopeState);

  final _ToastServiceScopeState _scopeState;

  final Queue<ToastRequest> _queue = Queue<ToastRequest>();
  OverlayEntry? _activeEntry;
  Timer? _autoDismissTimer;
  bool _disposed = false;

  // Completer used to wait for the overlay widget's exit animation before
  // processing the next queued toast.
  Completer<void>? _exitCompleter;

  // ---- ToastService API ---------------------------------------------------

  @override
  void show({
    required String message,
    required ToastVariant variant,
    Duration? duration,
  }) {
    // Guard: empty message → no-op.
    if (message.trim().isEmpty) return;

    // Guard: post-disposal → no-op.
    if (_disposed || !_scopeState.mounted) return;

    final request = ToastRequest(
      message: message,
      variant: variant,
      duration: duration,
    );

    _queue.add(request);
    _enforceQueueLimit();
    _processQueue();
  }

  @override
  void dismiss() {
    if (_disposed) return;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _removeActiveEntry();
    _queue.clear();
  }

  // ---- Internal -----------------------------------------------------------

  /// Drop oldest queued (non-active) entries when the queue exceeds the limit.
  void _enforceQueueLimit() {
    while (_queue.length > _kMaxQueueSize) {
      _queue.removeFirst();
    }
  }

  void _processQueue() {
    if (_disposed || !_scopeState.mounted) return;
    if (_activeEntry != null) return;
    if (_queue.isEmpty) return;

    // Guard: overlay must be available before inserting.
    OverlayState? overlay;
    try {
      overlay = Overlay.of(_scopeState.context, rootOverlay: true);
    } catch (_) {
      // Overlay not ready yet — retry on next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _processQueue());
      return;
    }

    final request = _queue.removeFirst();
    _exitCompleter = Completer<void>();

    _activeEntry = OverlayEntry(
      builder: (context) => ToastOverlayWidget(
        request: request,
        onDismiss: _onToastDismissed,
      ),
    );

    overlay.insert(_activeEntry!);

    _autoDismissTimer = Timer(request.duration, () {
      _onToastDismissed();
    });
  }

  void _onToastDismissed() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _removeActiveEntry();

    // Allow the next toast in the queue to display.
    if (!_disposed && _scopeState.mounted) {
      // Use a microtask so the overlay has time to clean up.
      Future.microtask(() => _processQueue());
    }
  }

  void _removeActiveEntry() {
    final entry = _activeEntry;
    _activeEntry = null;
    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {
        // Entry was never inserted or already removed — safe to ignore.
      }
    }
    if (_exitCompleter != null && !_exitCompleter!.isCompleted) {
      _exitCompleter!.complete();
    }
    _exitCompleter = null;
  }

  void _dispose() {
    _disposed = true;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _removeActiveEntry();
    _queue.clear();
  }
}

// ---------------------------------------------------------------------------
// Placeholder removed – replaced by ToastOverlayWidget in
// toast_overlay_widget.dart (Task 3).
// ---------------------------------------------------------------------------
