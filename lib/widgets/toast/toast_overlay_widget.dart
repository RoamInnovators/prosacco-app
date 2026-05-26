import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../theme/prosacco_palette.dart';
import 'toast_variant.dart';

/// The visual toast card rendered inside an [OverlayEntry].
///
/// Displays an icon, message text, and dismiss button with variant-specific
/// theming from [ProsaccoPalette]. Animates in with slide-down + fade-in and
/// animates out with fade-out on dismiss.
class ToastOverlayWidget extends StatefulWidget {
  const ToastOverlayWidget({
    super.key,
    required this.request,
    required this.onDismiss,
  });

  final ToastRequest request;
  final VoidCallback onDismiss;

  @override
  State<ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<ToastOverlayWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _fadeOutAnimation;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    // Entrance: slide down + fade in over 300ms.
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _fadeInAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    // Exit: fade out over 200ms.
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOut,
    ));

    _entranceController.forward();

    // Announce the toast message to assistive technologies.
    SemanticsService.announce(widget.request.message, TextDirection.ltr);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _triggerExit() {
    if (_exiting) return;
    _exiting = true;
    _exitController.forward().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final mapping = _variantMapping(pal, widget.request.variant);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: FadeTransition(
            opacity: _fadeOutAnimation,
            child: Semantics(
              label: '${widget.request.variant.name}: ${widget.request.message}',
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: mapping.background,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(mapping.icon, color: mapping.iconColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.request.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: mapping.textColor,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: mapping.iconColor),
                        onPressed: _triggerExit,
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant-specific color/icon mapping
// ---------------------------------------------------------------------------

class _VariantMapping {
  const _VariantMapping({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.textColor,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
}

_VariantMapping _variantMapping(ProsaccoPalette pal, ToastVariant variant) {
  switch (variant) {
    case ToastVariant.success:
      return _VariantMapping(
        background: pal.success.withValues(alpha: 0.12),
        icon: Icons.check_circle_outline,
        iconColor: pal.success,
        textColor: pal.onSurface,
      );
    case ToastVariant.error:
      return _VariantMapping(
        background: pal.errorContainer,
        icon: Icons.error_outline,
        iconColor: pal.error,
        textColor: pal.onErrorContainer,
      );
    case ToastVariant.warning:
      return const _VariantMapping(
        background: Color(0xFFFFF8E1),
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFF57F17),
        textColor: Color(0xFF5D4037),
      );
    case ToastVariant.info:
      return _VariantMapping(
        background: pal.primaryContainer.withValues(alpha: 0.12),
        icon: Icons.info_outline,
        iconColor: pal.primaryContainer,
        textColor: pal.onSurface,
      );
  }
}
