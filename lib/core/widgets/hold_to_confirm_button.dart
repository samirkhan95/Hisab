import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisab/core/constants.dart';

class HoldToConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final bool isLoading;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.isLoading = false,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
        _controller.reset();
        setState(() => _isHolding = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isLoading) return;
    setState(() => _isHolding = true);
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
    setState(() => _isHolding = false);
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isHolding ? 0.98 : 1.0,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Progress Fill
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _controller.value,
                    heightFactor: 1.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
              // Content
              Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Text(
                            widget.label,
                            style: TextStyle(
                              color: _controller.value > 0.5
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
