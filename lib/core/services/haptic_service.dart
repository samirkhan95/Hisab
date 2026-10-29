import 'package:flutter/services.dart';

class HapticService {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void success() => HapticFeedback.vibrate();
  static void error() => HapticFeedback.vibrate(); // Could be more complex if needed
}
