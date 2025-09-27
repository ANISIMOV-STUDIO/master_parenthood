// lib/widgets/enhanced_optimized_widgets.dart
// ⚡ Enhanced Optimized Widgets - Material 3 + Performance 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

/// 🎯 High-performance card with Material 3 styling and const optimization
class EnhancedCard extends StatelessWidget {
  const EnhancedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.color,
    this.elevation = 2,
    this.borderRadius = 16,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double elevation;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      elevation: elevation,
      color: gradient == null ? color : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: gradient != null
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            )
          : Padding(
              padding: padding,
              child: child,
            ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// 🔄 Advanced loading widget with multiple animation styles
class EnhancedLoadingWidget extends StatefulWidget {
  const EnhancedLoadingWidget({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 3,
    this.style = LoadingStyle.circular,
  });

  final double size;
  final Color? color;
  final double strokeWidth;
  final LoadingStyle style;

  @override
  State<EnhancedLoadingWidget> createState() => _EnhancedLoadingWidgetState();
}

enum LoadingStyle { circular, pulse, bounce, wave, dots }

class _EnhancedLoadingWidgetState extends State<EnhancedLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.style == LoadingStyle.wave ? 1500 : 1000),
      vsync: this,
    );

    switch (widget.style) {
      case LoadingStyle.pulse:
        _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _controller.repeat(reverse: true);
        break;
      case LoadingStyle.bounce:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        _controller.repeat();
        break;
      case LoadingStyle.wave:
      case LoadingStyle.dots:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.linear),
        );
        _controller.repeat();
        break;
      default:
        _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;

    switch (widget.style) {
      case LoadingStyle.pulse:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );

      case LoadingStyle.bounce:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -widget.size * 0.3 * (1 - (_animation.value - 0.5).abs() * 2).clamp(0.0, 1.0)),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );

      case LoadingStyle.wave:
        return SizedBox(
          width: widget.size * 3,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final animValue = (_animation.value + delay) % 1.0;
                  final scale = 0.5 + 0.5 * (1 - (animValue - 0.5).abs() * 2).clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 0.25,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: color.withOpacity(scale),
                        borderRadius: BorderRadius.circular(widget.size * 0.125),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );

      case LoadingStyle.dots:
        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 0.5,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final animValue = (_animation.value + delay) % 1.0;
                  final opacity = (1 - (animValue - 0.5).abs() * 2).clamp(0.3, 1.0);

                  return Container(
                    width: widget.size * 0.15,
                    height: widget.size * 0.15,
                    decoration: BoxDecoration(
                      color: color.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        );

      default:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: widget.strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
    }
  }
}

/// 📱 Enhanced Material 3 button with haptic feedback and micro-interactions
class EnhancedButton extends StatefulWidget {
  const EnhancedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.hapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.buttonType = ButtonType.elevated,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool hapticFeedback;
  final Duration animationDuration;
  final ButtonType buttonType;
  final IconData? icon;
  final bool loading;

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

enum ButtonType { elevated, filled, outlined, text }

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.loading) {
      _animationController.forward();
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.loading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.loading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = widget.loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.child,
            ],
          )
        : widget.icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18),
                  const SizedBox(width: 8),
                  widget.child,
                ],
              )
            : widget.child;

    Widget button;

    switch (widget.buttonType) {
      case ButtonType.filled:
        button = FilledButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: widget.style,
          child: buttonChild,
        );
        break;
      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: widget.style,
          child: buttonChild,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: widget.style,
          child: buttonChild,
        );
        break;
      default:
        button = ElevatedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: widget.style,
          child: buttonChild,
        );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: button,
          );
        },
      ),
    );
  }
}

/// 🎨 Modern gradient container with Glass morphism support
class EnhancedGradientContainer extends StatelessWidget {
  const EnhancedGradientContainer({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.glassMorphism = false,
    this.shadowColor,
    this.elevation = 0,
    this.border,
  });

  final Widget child;
  final Gradient? gradient;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool glassMorphism;
  final Color? shadowColor;
  final double elevation;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    if (glassMorphism) {
      return Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: borderRadius,
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: elevation > 0
                  ? [
                      BoxShadow(
                        color: (shadowColor ?? Colors.black).withOpacity(0.1),
                        blurRadius: elevation * 2,
                        offset: Offset(0, elevation),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: (shadowColor ?? Colors.black).withOpacity(0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// 📊 Performance-optimized list item with Material 3 styling
class EnhancedListItem extends StatelessWidget {
  const EnhancedListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.enabled = true,
    this.semanticLabel,
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool enabled;
  final String? semanticLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: semanticLabel ?? title,
          enabled: enabled,
          child: ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: enabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
            leading: leading,
            trailing: trailing,
            onTap: enabled ? onTap : null,
            dense: dense,
            enabled: enabled,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: leading != null ? 72 : 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
      ],
    );
  }
}

/// 🌊 Enhanced shimmer loading effect
class EnhancedShimmer extends StatelessWidget {
  const EnhancedShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Shimmer.fromColors(
      baseColor: baseColor ??
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      highlightColor: highlightColor ??
        Theme.of(context).colorScheme.surface,
      period: period,
      child: child,
    );
  }
}

/// 🎯 Smart responsive layout helper
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// 🔄 Adaptive refresh indicator
class AdaptiveRefreshIndicator extends StatelessWidget {
  const AdaptiveRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      color: color ?? AppTheme.primaryColor,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}

/// 📱 Modern snack bar helper
class ModernSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = AppTheme.successColor;
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = AppTheme.errorColor;
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = AppTheme.warningColor;
        icon = Icons.warning_outlined;
        break;
      default:
        backgroundColor = AppTheme.infoColor;
        icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }
}

enum SnackBarType { info, success, error, warning }