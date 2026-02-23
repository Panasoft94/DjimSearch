import 'package:flutter/material.dart';

/// Bouton retour personnalisé et réutilisable
class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: color ?? colorScheme.onSurface,
          size: size,
        ),
        onPressed: onPressed ?? () => Navigator.pop(context),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surface,
          side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
    );
  }
}

