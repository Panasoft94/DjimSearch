import 'package:flutter/material.dart';
import '../utils/design_constants.dart';

/// Barre de recherche personnalisée avec design inspiré de Google
/// Supporte le mode petit (AppBar) et le mode grand (Écran d'accueil)
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onMicPressed;
  final bool isSmall;
  final bool isListening;
  final String hintText;
  final bool showMicButton;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.onMicPressed,
    this.isSmall = false,
    this.isListening = false,
    this.hintText = 'Rechercher ou saisir une URL',
    this.showMicButton = true,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _shadowAnimation = Tween<double>(begin: 1.0, end: 8.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFocused = widget.focusNode.hasFocus;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                widget.isSmall ? Spacing.radiusRound : Spacing.radiusRound,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.12),
                  blurRadius: _shadowAnimation.value,
                  spreadRadius: _shadowAnimation.value * 0.5,
                  offset: Offset(0, _shadowAnimation.value * 0.25),
                )
              ],
            ),
            child: Container(
              height: widget.isSmall ? 48 : 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Spacing.radiusRound),
                color: isFocused
                    ? colorScheme.surface
                    : colorScheme.surfaceVariant.withOpacity(0.6),
                border: Border.all(
                  color: isFocused
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.2),
                  width: isFocused ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Search icon with animation
                  Padding(
                    padding: EdgeInsets.only(left: widget.isSmall ? 14 : 16),
                    child: AnimatedIconButton(
                      icon: Icons.search,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                      isActive: isFocused,
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  // TextField
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      style: TextStyle(
                        fontSize: widget.isSmall ? 14 : 16,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: widget.isSmall ? 14 : 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: widget.isSmall ? 8 : 12,
                          vertical: 0,
                        ),
                      ),
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                  // Microphone button
                  if (widget.showMicButton)
                    Padding(
                      padding: EdgeInsets.only(right: widget.isSmall ? 8 : 12),
                      child: MicrophoneButton(
                        onPressed: widget.onMicPressed,
                        isListening: widget.isListening,
                        isSmall: widget.isSmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bouton icône avec animation au focus/hover
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? activeColor;
  final double size;
  final VoidCallback? onPressed;
  final bool isActive;

  const AnimatedIconButton({
    Key? key,
    required this.icon,
    required this.color,
    this.activeColor,
    this.size = 24,
    this.onPressed,
    this.isActive = false,
  }) : super(key: key);

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(AnimatedIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: Icon(
            widget.icon,
            color: widget.isActive
                ? (widget.activeColor ?? widget.color)
                : widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Bouton microphone avec animation et feedback
class MicrophoneButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isListening;
  final bool isSmall;

  const MicrophoneButton({
    Key? key,
    this.onPressed,
    this.isListening = false,
    this.isSmall = false,
  }) : super(key: key);

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );

    _colorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.primary,
      end: Theme.of(context).colorScheme.error,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.forward();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.reverse();
    }
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
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(Spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.all(widget.isSmall ? 6 : 8),
                child: Icon(
                  widget.isListening ? Icons.graphic_eq : Icons.mic,
                  color: _colorAnimation.value,
                  size: widget.isSmall ? 20 : 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
