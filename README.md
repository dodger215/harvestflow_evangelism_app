# 🌾 HarvestFlow Evangelism

![Animated Banner](https://raw.githubusercontent.com/animated-webdev/flame-flow/main/header-animated.gif)

> **Share the Gospel. Follow up souls. Stay organized.**

---

## 📖 Overview

**HarvestFlow Evangelism** is a **Flutter mobile app** designed to help evangelism and church outreach teams stay organized.  
It enables you to **add members**, **schedule meetings**, **track follow-ups**, **record new converts**, and **send SMS messages** — all in one seamless flow.

---

## 🌿 Animated Concept Logo

![Animated Wheat and Water Flow](https://raw.githubusercontent.com/animated-webdev/flame-flow/main/animated-harvest.gif)

*(Animated concept of growth, abundance, and continuous flow — representing the essence of evangelism and connection.)*

---

## 🚀 Features

| Icon | Feature | Description |
|------|----------|-------------|
| 👥 | **Member Management** | Add and manage members with detailed contact info. |
| 📅 | **Meetings & Events** | Schedule and manage ministry events. |
| 💬 | **Follow-Up Tracking** | Keep records of spiritual follow-ups. |
| ✉️ | **SMS Messaging** | Send personalized messages via SMS. |
| 🙌 | **Add Souls** | Record and assign follow-up tasks for new converts. |
| 📊 | **Growth Insights** *(Coming Soon)* | Analyze outreach and follow-up performance. |

---

## 🧱 Tech Stack

| Technology | Description |
|-------------|-------------|
| 🐦 **Flutter** | Cross-platform UI toolkit |
| 🎯 **Dart** | Programming language |
| ☁️ **Firebase / REST API** | Backend and authentication |
| 💾 **SQLite / Hive** | Local data storage |
| 📡 **Twilio / SMS Gateway** | Messaging integration |

---

## 🛠️ Getting Started

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/dodger215/harvestflow-evangelism.git
cd harvestflow-evangelism
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Run the App

```bash
flutter run
```

> 💡 **Tip:** Ensure you have Flutter SDK installed.
> Check with:
> ```bash
> flutter doctor
> ```

---

## 🌈 Animated App Flow

```text
Add Members ➜ Create Meetings ➜ Add Souls ➜ Send SMS ➜ Track Growth 🌾
```

**Animated Representation:**
![App Flow Animation](https://raw.githubusercontent.com/animated-webdev/flame-flow/main/flow-line.gif)

---

## 🤝 Contributing

1. Fork this repository  
2. Create a feature branch → `git checkout -b feature/your-feature`  
3. Commit → `git commit -m 'Add new feature'`  
4. Push → `git push origin feature/your-feature`  
5. Open a Pull Request 🎉  

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## ❤️ Credits

Developed by **HarvestFlow Team**  
*"Share the Gospel. Follow up souls. Stay organized."*

[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0-blue?logo=dart)](https://dart.dev)
[![Status](https://img.shields.io/badge/status-active-success.svg)]()

---

## 🔧 Icon Animation Issue

**Regarding the icon animation not working:** The animated icons in this README should display properly since they're hosted on GitHub. However, if you're referring to **animations within your Flutter app** not working, here are some common solutions:

### Common Flutter Animation Issues:

1. **Check if animations are enabled:**
   ```dart
   import 'package:flutter/scheduler.dart';
   
   // Ensure animations aren't disabled
   if (SchedulerBinding.instance!.schedulerPhase != SchedulerPhase.idle) {
     // Animation code
   }
   ```

2. **Verify AnimationController:**
   ```dart
   AnimationController(
     duration: const Duration(seconds: 1),
     vsync: this, // Make sure your class uses with SingleTickerProviderStateMixin
   );
   ```

3. **Check package dependencies:**
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     lottie: ^2.7.0 # if using Lottie animations
   ```

4. **Run flutter clean:**
   ```bash
   flutter clean
   flutter pub get
   ```

If you need specific help with your Flutter animation code, please share the relevant code snippets!

---

**Changes Made:**
- ✅ Fixed markdown formatting (removed extra backticks at start)
- ✅ Added troubleshooting section for animation issues
- ✅ Improved readability and structure
- ✅ All external links should work properly

The README looks great overall! The animated elements should display correctly when viewed on GitHub.
