# Rescu Assessment — Solutions (Thanawat Butseree)

## 1. Tickets & Features Completed
*(เว้นไว้ใส่คำอธิบายบั๊กและฟีเจอร์ที่เราทำเสร็จ เช่น RES-101, RES-106, F-1)*

---

## 2. AI Usage Log

### Tools Used & Purpose
- **Gemini (AI Collaborator / Tech Lead Persona):**
  - **Cross-Stack Knowledge Transfer:** Since my primary background is in Full-Stack Web/Mobile development with **React / React Native (TypeScript)** and **ASP.NET Core (C#)**, I used AI to build a mental map translating my existing knowledge into **Flutter (Dart)** and **GetX** concepts before writing any code.
  - **Environment Setup & Toolchain Debugging:** Used to set up the pinned toolchain (`Flutter 3.27.0` via `fvm` and `Java 17`) on Windows and diagnose Gradle/SDK version conflicts.
  - **Ticket Triage & Root Cause Brainstorming:** Used to analyze problem descriptions in `PROBLEM.md` and plan a depth-first debugging strategy.

---

### Concrete Examples Where AI Was Wrong or Misleading (And How I Fixed It)

#### Example 1: Outdated Package Manager & Broken Installation URLs for FVM on Windows
- **What AI suggested:** To install FVM on Windows, the AI initially suggested running `winget install LeoFarias.Fvm`, and subsequently suggested running an official PowerShell install script via `iwr -useb https://fvm.app/install.ps1 | iex`.
- **How I caught it:** Both commands failed immediately. `winget` returned `No package found matching input criteria`, and the `fvm.app/install.ps1` URL returned a `404: This page could not be found` HTML payload from Next.js because the FVM documentation site had migrated its structure. Furthermore, when falling back to Chocolatey (`choco install fvm`), the script failed with a runtime exception because the AI did not initially verify that the shell was running with elevated Administrator privileges, leaving a half-configured `ChocolateyInstall` user variable.
- **What I did instead:** I opened an elevated Administrator PowerShell session, cleaned up the leftover `ChocolateyInstall` environment variable and temporary folder to prevent path conflicts, installed Chocolatey cleanly, and installed FVM (`v4.3.2`). I also enabled Windows Developer Mode to allow FVM to create symbolic links for `Flutter 3.27.0`.

#### Example 2: Deprecated `--android-licenses` Flag on Newer Android SDK CLI (2026)
- **What AI suggested:** When `fvm flutter doctor` flagged `Android license status unknown`, both Flutter's built-in prompt and the AI instructed me to run `fvm flutter doctor --android-licenses` and accept the prompts with `y`.
- **How I caught it:** Running the command produced a deprecation warning: `WARNING: The SDK Manager CLI tool (sdkmanager) is deprecated. Android CLI will be used instead... Warning: The --licenses option is no longer needed.` Because my machine had Android Studio `2026.2.1` (Android SDK 36.0.0) installed, the newer command-line tools rejected the legacy `--licenses` flag invoked by Flutter `3.27.0`.
- **What I did instead:** Instead of getting stuck in the CLI loop, I recognized the version gap between Flutter 3.27.0 (pinned by the assessment) and the 2026 Android SDK tools, and managed SDK licenses/components directly via Android Studio's SDK Manager.

#### Example 3: Misleading "Flutter Fix" Prompt on Gradle/Java Incompatibility (`Major Version 69`)
- **What the tooling/AI suggested:** When running `fvm flutter run`, the build crashed with `Unsupported class file major version 69` in `settings.gradle`. Flutter's built-in diagnostic box (`Flutter Fix`) explicitly suggested updating the Gradle version inside `android/gradle/wrapper/gradle-wrapper.properties` to match the Java version being used.
- **How I caught it:** 
  1. I checked the Ground Rules in `PROBLEM.md`, which strictly state: *"Do not upgrade Flutter or any package. Toolchain is pinned: Flutter 3.27.0, Java 17"*. Modifying `gradle-wrapper.properties` would violate the assessment rules.
  2. Even though `java -version` in my terminal correctly showed `OpenJDK 17.0.21`, class file major version `69` corresponds to **Java 25**. I realized Flutter was ignoring my system `PATH` and silently using the bundled JBR (Java 25) shipped inside Android Studio `2026.2.1`.
- **What I did instead:** I kept `gradle-wrapper.properties` untouched. I located my actual Microsoft OpenJDK 17 installation path using `(Get-Command java).Source` (`C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot`) and explicitly bound Flutter to it via `fvm flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot"`. The build then succeeded cleanly without modifying any project configuration files.

---

## 3. Design Questions
### Q1: GetxController lifecycle vs. Widget State lifecycle
*(เว้นไว้ตอบคำถามข้อ 1)*

### Q2: Scoping reactivity with Obx
*(เว้นไว้ตอบคำถามข้อ 2)*

### Q3: Automated testing for RES-106
*(เว้นไว้ตอบคำถามข้อ 3)*

---

## 4. Time Spent & Next Steps
*(เว้นไว้สรุปเวลาที่ใช้จริง และสิ่งที่จะทำต่อถ้ามีเวลาเพิ่มอีก 1 วัน)*