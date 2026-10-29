import 'package:flutter/material.dart';
import 'package:hisab/core/constants.dart';
import 'package:hisab/core/services/haptic_service.dart';
import 'dart:math' as math;

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final VoidCallback onAddTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Notched Background
          CustomPaint(
            size: const Size(double.infinity, 70),
            painter: NotchedBarPainter(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.primaryLight,
              shadowColor: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          // Navigation Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _NavBarIcon(
                  icon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () {
                    HapticService.light();
                    onDestinationSelected(0);
                  },
                ),
              ),
              Expanded(
                child: _NavBarIcon(
                  icon: Icons.search_rounded,
                  isSelected: currentIndex == 1,
                  onTap: () {
                    HapticService.light();
                    onDestinationSelected(1);
                  },
                ),
              ),
              // Spacer for the middle button
              const SizedBox(width: 70),
              Expanded(
                child: _NavBarIcon(
                  icon: Icons.notifications_rounded,
                  isSelected: currentIndex == 2,
                  onTap: () {
                    HapticService.light();
                    onDestinationSelected(2);
                  },
                ),
              ),
              Expanded(
                child: _NavBarIcon(
                  icon: Icons.person_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () {
                    HapticService.light();
                    onDestinationSelected(3);
                  },
                ),
              ),
            ],
          ),
          // The Floating Middle Button
          Positioned(
            top: -25, // Pop out of the bar
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticService.medium();
                  onAddTap();
                },
                child: Container(
                  height: 65,
                  width: 65,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey[700],
          size: 28,
        ),
      ),
    );
  }
}

class NotchedBarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  NotchedBarPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 35.0; // Roundness of the bar ends
    const notchRadius = 45.0; // Radius of the middle dip

    // Start from left
    path.moveTo(radius, 0);
    
    // Left notched curve
    final notchWidth = notchRadius * 2;
    final notchStart = (size.width - notchWidth) / 2;

    path.lineTo(notchStart, 0);
    
    // Smooth notch curve
    path.quadraticBezierTo(
      notchStart + notchRadius / 2, 0,
      notchStart + notchRadius / 2, notchRadius / 3, // Shallower start
    );
    
    // Draw the circular notch - adjusted depth to match button
    // Center at 5, radius at 36 (button bottom is at ~40)
    path.arcTo(
      Rect.fromCircle(center: Offset(size.width / 2, 5), radius: 36),
      math.pi,
      -math.pi,
      false,
    );

    path.quadraticBezierTo(
      size.width - (notchStart + notchRadius / 2), 0,
      size.width - notchStart, 0,
    );

    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Draw Shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.3), 15.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
