import 'package:flutter/material.dart';
import 'package:hisab/core/constants.dart';

import 'package:hisab/core/services/haptic_service.dart';

class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirm,
    this.text = 'Tap and hold to post',
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
      duration: const Duration(milliseconds: 800), // Even faster: 0.8s
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticService.success();
        widget.onConfirm();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_controller.status == AnimationStatus.forward ||
        _controller.status == AnimationStatus.completed) {
      return;
    }
    HapticService.light();
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isHolding = false);
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    setState(() => _isHolding = false);
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100, // Reduced height
        width: double.infinity,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background with Subtle Curved Top
            ClipPath(
              clipper: BottomArcClipper(),
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppColors.primary.withValues(alpha: 0.05), // Subtler (from 0.1 to 0.05)
              ),
            ),
            // Filling Progress (Left to Right)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipPath(
                  clipper: BottomArcClipper(),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    alignment: Alignment.bottomLeft,
                    child: FractionallySizedBox(
                      widthFactor: _controller.value,
                      heightFactor: 1.0,
                      child: Container(color: AppColors.primary),
                    ),
                  ),
                );
              },
            ),
            // Content
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _isHolding ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.send,
                      color: _controller.value > 0.5 ? Colors.white : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: _controller.value > 0.5 ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    // Starting the curve higher up
    path.lineTo(0, 30);
    // Lower control point to make the curve/radius smaller (less "bulge")
    path.quadraticBezierTo(size.width / 2, 0, size.width, 30);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
