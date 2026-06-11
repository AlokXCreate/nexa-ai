import 'package:flutter/material.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final IconData? icon;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.label,
      onTap: widget.onPressed,
      child: GestureDetector(
        onTapDown: (_) => isDisabled ? null : _controller.forward(),
        onTapUp: (_) => isDisabled ? null : _controller.reverse(),
        onTapCancel: () => isDisabled ? null : _controller.reverse(),
        onTap: widget.onPressed,
        child: Transform.scale(
          scale: _scale,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: widget.isSecondary ? null : AppColors.primaryGradient,
              color: widget.isSecondary ? AppColors.surfaceElevated : null,
              border: widget.isSecondary ? Border.all(color: AppColors.border, width: 1.0) : null,
              boxShadow: widget.isSecondary
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
