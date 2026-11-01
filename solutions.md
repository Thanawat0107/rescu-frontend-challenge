# Rescu Assessment — Solutions (Thanawat Butseree)

## 1. Tickets & Features Completed
*(เว้นไว้ใส่คำอธิบายบั๊กและฟีเจอร์ที่เราทำเสร็จ เช่น RES-101, RES-106, F-1)*

---

## 2. AI Usage Log

### Tools Used & Purpose
- **Gemini (AI Collaborator / Tech Lead Persona):**
  - **Cross-Stack Knowledge Transfer & Language Semantics:** Since my primary background is in Full-Stack Web/Mobile development with **React / React Native (TypeScript)** and **ASP.NET Core (C#)**, I used AI to build a mental map translating my existing knowledge into **Flutter (Dart)** and **GetX** concepts:
    - Compared immutability and memory optimization: `final` (runtime read-only, equivalent to C# `readonly` / TS `const`) vs `const` (compile-time canonical instance, e.g. `const Duration(...)`).
    - Clarified Dart type inference idioms (e.g. why `final int` is redundant vs idiomatic `final` under Effective Dart guidelines, and `num`/`int`/`double` vs TS `number`).
  - **Reverse-Engineering Backend Latency & Concurrency Models:** Used AI to dissect the latency simulation formula inside `FakeApiService.searchDeals` (`broadness = max(0, 1200 - length * 280)`). This helped pinpoint why broad queries take ~1.3s while narrow queries take ~0.2s, modeling how out-of-order responses create Race Conditions (RES-101) and defining the async request sequence tag strategy (`_activeSearchId`).
  - **Toolchain & Environment Setup:** Diagnosed Windows toolchain setup (`Flutter 3.27.0` via `fvm` and `Java 17`) to isolate Gradle/SDK version mismatches without modifying project configurations.
  - **Strategic Assessment Triage & ROI Prioritization:** Used AI as a technical soundboard to evaluate assessment trade-offs under a tight timeline ("Depth over volume"). Prioritized high-signal tickets (RES-101, RES-102, RES-103, RES-106) that directly provide empirical foundation for the required Design Questions (Q1, Q2, Q3), and selected F-1 (Live Countdowns) to rigorously demonstrate Flutter Render Tree & Rebuild Scoping via DevTools profiling.
  - **Memory Leak & Lifecycle Architecture Audit:** Collaborated with AI to audit lifecycle boundaries between GetX Controllers and Flutter Widget States:
    - Analyzed dangling timer mechanics in `PickupCountdown` (RES-102) where unmounted widgets invoke `setState()`.
    - Identified global event subscription leaks in `DealDetailsController` (RES-103) where `Worker` instances bound to a permanent singleton (`CartService`) were never released via `Worker.dispose()`.
    - Audited ISO-8601 UTC contract handling in `PickupWindowModel` (RES-106) to enforce `.toLocal()` normalization and complete date tuple matching (`year`, `month`, `day`).
  - **Zero-Dependency Test Architecture Dissection:** Collaborated with AI to analyze and verify the in-memory test architecture inside `test/search_race_condition_test.dart`. Analyzed how `FakeDealRepo` operates as a spy repository (tracking `searchCallCount` and `searchQueries`) with an `onSearch` callback to deterministically inject network delay and simulate race conditions without external mocking packages (`mockito`/`mocktail`), strictly adhering to Ground Rule 3.

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

#### Example 4: AI's Unrealistic 300ms Debounce Ignored Real-World Mobile Typing Cadence
- **What AI suggested:** The AI initially recommended a standard `300ms` debounce timer for `SearchDealsController.onQueryChanged`.
- **How I caught it:** When performing manual tests on an Android virtual keyboard, I inspected the network log and noticed that bursts of intermediate queries (`sus`, `sush`, `sushi`) were still slipping through. Real humans typing on mobile devices—especially when spelling unfamiliar words or pausing to check if instant results have appeared—typically average **400–500ms** between keystrokes. A 300ms debounce proved too aggressive and unreflective of authentic user behavior.
- **What I did instead:** Rather than accepting the AI's default, I pushed back and adjusted the debounce duration to `500ms` (0.5s). This provides a comfortable typing window without introducing noticeable perceived latency, drastically reduces redundant network payload and battery consumption, and allows the backend to handle single, high-confidence queries. I also updated the automated tests in `test/search_race_condition_test.dart` to validate this 500ms threshold.

#### Example 5: AI's Naive Suggestion to Wrap `DealDetailsController` with `fenix: true` to Fix Memory Leak
- **What AI suggested:** When diagnosing why `_recheckAvailability` fired repeatedly for previously viewed deals (RES-103), the AI initially suggested modifying `DealDetailsBinding` to use `Get.lazyPut(..., fenix: true)`.
- **How I caught it:** While `fenix: true` allows recreation of disposed controllers, it did not address the actual root cause: the `ever(cartService.itemCount, ...)` worker attaches an anonymous stream subscription directly into `cartService.itemCount` (which is a `permanent: true` global singleton). Because `cartService` lives for the entire application session, its internal listener list retained the callback closures regardless of whether the binding used `fenix`.
- **What I did instead:** Instead of altering binding flags, I stored the `Worker` reference (`Worker? _cartWorker`) inside `DealDetailsController` and explicitly disposed it during the controller's teardown:
  ```dart
  @override
  void onClose() {
    _cartWorker?.dispose();
    super.onClose();
  }
  ```
  This cleanly unhooks the listener from the singleton service when the user leaves the screen, completely halting redundant network calls.

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
