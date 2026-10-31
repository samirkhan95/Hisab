# 💸 Hisab — Modern Shared Expense & Debt Ledger App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Cross--Platform-green?style=for-the-badge&logo=android)](https://android.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Riverpod-orange?style=for-the-badge)](https://riverpod.dev)
[![Status](https://img.shields.io/badge/Build-Release%20Ready-brightgreen?style=for-the-badge)]()

**Hisab** is a production-grade, real-time shared expense tracking and peer-to-peer debt ledger application built with **Flutter**, **Riverpod**, and **Firebase**. Designed for individuals, roomies, and friend groups, Hisab streamlines expense splits, balance calculation, and financial settlements with a sleek, modern UI and tactile UX animations.

---

## 📱 Try the Live App (Release APK)

You can experience the fully compiled app directly on your Android device without building from source:

📥 **[Download Latest Release APK](https://github.com/samirkhan95/Hisab/releases/latest)**

> **Note for Reviewers & Recruiters:** This showcase repository highlights the architecture, design system, and core technical implementations of Hisab. The production-ready pre-built APK is provided above for full hands-on testing.

---

## ✨ Key Features

- 📊 **Real-Time Net Balance Ledger**: Dynamic real-time calculation of who owes what across all active transactions.
- ⚡ **Tactile "Hold-to-Confirm" Settlements**: Interactive, hold-to-activate button with custom progress animations and haptic feedback to prevent accidental financial settlements.
- 🔐 **Firebase Authentication**: Secure user login, registration, dynamic profile management, and session state persistence.
- 🔔 **Push & Local Notifications**: Powered by Firebase Cloud Messaging (FCM) and `flutter_local_notifications` for real-time transaction updates.
- 🔍 **Instant Search & Dynamic Filters**: Filter transactions by friends, categories, or search queries instantaneously.
- 🎨 **Floating Navigation & Modern UI**: Custom floating bottom navigation bar with responsive layouts and smooth screen transitions.
- 📁 **Archive & Expense History**: Archive completed or settled expenses to keep your primary dashboard uncluttered.

---

## 📸 App Screenshots

| Dashboard & Balance | Expense Split Sheet | Tactile Settlement | Profile & Archive |
| :---: | :---: | :---: | :---: |
| *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* |

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x)
- **State Management:** [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Navigation:** [`go_router`](https://pub.dev/packages/go_router)
- **Backend & Database:** Firebase Auth, Cloud Firestore, Firebase Storage
- **Push Notifications:** Firebase Cloud Messaging (FCM) & `flutter_local_notifications`
- **Styling:** Custom Material Theme, `google_fonts`, Custom Glassmorphism & Haptics
- **Architecture Pattern:** Clean Layered Architecture (MVVM + Riverpod)

```
lib/
├── main.dart                       # App entrypoint & Firebase initialization
├── core/                           # Shared core components & infrastructure
│   ├── constants.dart              # App constants, categories & icons
│   ├── theme.dart                  # Custom color palette & typography
│   ├── router.dart                 # Declarative route configuration (GoRouter)
│   ├── providers/                  # Global providers (Firebase, Theme, Auth)
│   ├── services/                   # Haptics & Notification Service engines
│   └── widgets/                    # Reusable widgets (HoldToConfirm, FloatingNavBar, Avatar)
└── features/                       # Feature-driven modular structure
    ├── auth/                       # Authentication (Login, Register, Splash)
    │   ├── providers/
    │   └── screens/
    ├── home/                       # Core ledger dashboard & settlement handling
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   └── widgets/
    ├── messages/                   # Transaction notes & communication ledger
    ├── notifications/              # Real-time alert notifications
    └── profile/                    # User profile settings & transaction archive
```

---

## 💡 Showcase Code Snippets

### 1. Reactive Balance Calculation (`Riverpod Stream & Derived State`)
```dart
final balanceProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) return 0.0;

  double balance = 0.0;
  for (final expense in expenses) {
    if (expense.status == 'settled' || expense.isArchived) continue;

    if (expense.paidBy == userId) {
      balance += expense.isSplit ? expense.amount / 2 : expense.amount;
    } else {
      balance -= expense.isSplit ? expense.amount / 2 : expense.amount;
    }
  }
  return balance;
});
```

### 2. Tactile Hold-to-Confirm Settlement Action
```dart
void _onHoldComplete() {
  HapticFeedback.heavyImpact();
  widget.onConfirmed();
  _controller.reset();
  setState(() => _isHolding = false);
}
```

---

## 🚀 How to Build Release APK

To generate the release build for testing on Android:

```bash
# 1. Clean build artifacts
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build optimized Release APK
flutter build apk --release
```

The output binary will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 💼 Showcase Repository Notice

This repository serves as a **Portfolio & Architecture Showcase** for project evaluation. 

- Core UI widgets, data models, state providers, and design tokens are included to showcase code quality and engineering standards.
- Pre-built binary releases are available under the [Releases](https://github.com/samirkhan95/Hisab/releases) tab.

---

## 👤 Author

Developed by **Samir Khan**  
- GitHub: [@samirkhan95](https://github.com/samirkhan95)

---

*Made with ❤️ using Flutter.*
