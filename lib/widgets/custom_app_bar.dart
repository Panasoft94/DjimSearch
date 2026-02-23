import 'package:flutter/material.dart';

/// AppBar personnalisé réutilisable avec design cohérent
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;
  final bool showBackButton;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final TextStyle? titleStyle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onLeadingPressed,
    this.showBackButton = true,
    this.elevation = 0,
    this.bottom,
    this.backgroundColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: Text(
        title,
        style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: Icon(Icons.arrow_back_rounded,
                      color: colorScheme.onSurface),
                  onPressed: onLeadingPressed ?? () => Navigator.pop(context),
                )
              : null),
      actions: actions,
      elevation: elevation,
      scrolledUnderElevation: 4,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

