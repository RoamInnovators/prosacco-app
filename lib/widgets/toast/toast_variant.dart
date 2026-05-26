/// Visual category of a toast notification.
enum ToastVariant { success, error, warning, info }

/// A request to display a toast notification.
///
/// Default durations are resolved at construction time:
/// - `success` / `info` → 3 seconds
/// - `error` / `warning` → 4 seconds
class ToastRequest {
  ToastRequest({
    required this.message,
    required this.variant,
    Duration? duration,
  }) : duration = duration ?? _defaultDuration(variant);

  final String message;
  final ToastVariant variant;
  final Duration duration;

  static Duration _defaultDuration(ToastVariant variant) {
    switch (variant) {
      case ToastVariant.success:
      case ToastVariant.info:
        return const Duration(seconds: 3);
      case ToastVariant.error:
      case ToastVariant.warning:
        return const Duration(seconds: 4);
    }
  }
}
