import 'package:flutter/material.dart';
import '../utils/design_constants.dart';

/// Carte réutilisable avec design cohérent et ombre subtile
class ShadowCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final bool clickable;

  const ShadowCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.margin = const EdgeInsets.all(0),
    this.elevation = 1,
    this.borderRadius = Spacing.radiusLarge,
    this.backgroundColor,
    this.clickable = true,
  }) : super(key: key);

  @override
  State<ShadowCard> createState() => _ShadowCardState();
}

class _ShadowCardState extends State<ShadowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget cardContent = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: widget.padding,
            margin: widget.margin,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: widget.elevation * 4,
                  spreadRadius: widget.elevation * 0.5,
                  offset: Offset(0, widget.elevation),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );

    if (widget.clickable && widget.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (isHovering) {
            if (isHovering) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

