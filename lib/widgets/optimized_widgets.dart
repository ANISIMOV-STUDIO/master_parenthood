// lib/widgets/optimized_widgets.dart
// 🚀 Optimized Widgets - Flutter 2025 Performance Best Practices
import 'package:flutter/material.dart';

/// Optimized card widget with const constructor
class OptimizedCard extends StatelessWidget {
  const OptimizedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.elevation = 4.0,
    this.borderRadius = 12.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Optimized gradient container with const constructor
class OptimizedGradientContainer extends StatelessWidget {
  const OptimizedGradientContainer({
    super.key,
    required this.child,
    required this.colors,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

/// Optimized loading widget that doesn't rebuild
class OptimizedLoadingWidget extends StatelessWidget {
  const OptimizedLoadingWidget({
    super.key,
    this.message = 'Loading...',
    this.showMessage = true,
  });

  final String message;
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Optimized cached image widget
class OptimizedCachedImage extends StatelessWidget {
  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
            SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.error),
            );
        },
      ),
    );
  }
}

/// Optimized list tile with const constructor
class OptimizedListTile extends StatelessWidget {
  const OptimizedListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Optimized animated container that prevents unnecessary rebuilds
class OptimizedAnimatedContainer extends StatefulWidget {
  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<OptimizedAnimatedContainer> createState() => _OptimizedAnimatedContainerState();
}

class _OptimizedAnimatedContainerState extends State<OptimizedAnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.curve.transform(_controller.value),
          child: widget.child,
        );
      },
    );
  }
}

/// Optimized refresh indicator
class OptimizedRefreshIndicator extends StatelessWidget {
  const OptimizedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      child: child,
    );
  }
}

/// Optimized sliver app bar
class OptimizedSliverAppBar extends StatelessWidget {
  const OptimizedSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.expandedHeight = 200.0,
    this.pinned = true,
    this.floating = false,
    this.flexibleSpace,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final Widget? flexibleSpace;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      flexibleSpace: flexibleSpace,
    );
  }
}

/// Optimized separator widget
class OptimizedSeparator extends StatelessWidget {
  const OptimizedSeparator({
    super.key,
    this.height = 1.0,
    this.color,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
  });

  final double height;
  final Color? color;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      color: color ?? Theme.of(context).dividerColor,
    );
  }
}

/// Optimized hero widget for smooth transitions
class OptimizedHero extends StatelessWidget {
  const OptimizedHero({
    super.key,
    required this.tag,
    required this.child,
    this.transitionOnUserGestures = false,
  });

  final Object tag;
  final Widget child;
  final bool transitionOnUserGestures;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: transitionOnUserGestures,
      child: child,
    );
  }
}

/// Optimized page transition
class OptimizedPageRoute<T> extends PageRouteBuilder<T> {
  OptimizedPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          transitionDuration: duration,
        );

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }
}