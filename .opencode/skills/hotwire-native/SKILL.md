---
name: Hotwire Native
description: Build and modify Hotwire Native iOS and Android apps. Use for creating projects, native tab bars, path configuration, bridge components, native screens, and the full iOS (Swift) and Android (Kotlin) APIs. Covers the entire native.hotwired.dev documentation.
---

# Hotwire Native

Hotwire Native is a framework for building native mobile apps that render web
content in a native shell. A web app (typically Rails + Turbo) drives the UI
inside a native `WebView`, while the framework intercepts link taps and routes
them through native navigation — pushing screens on a navigation stack,
presenting modals, and swapping in fully native screens where it helps.

Start with the concept pages if the question is "how does this work"; jump
straight to the platform references when the question is "how do I write this".

## Core concepts

- **Navigator** — the central object on each platform. It owns the navigation
  stack, decides how to present a destination, and exposes delegate hooks.
- **Path configuration** — a JSON document (`settings` + `rules`) served by your
  web app that maps URL regex patterns to navigation properties such as
  `context` (default/modal) and `presentation` (push, replace, pop, …).
- **Bridge components** — a web (Stimulus) component plus a matching native
  component that exchange messages over the `bridge` channel.
- **Native screens** — route a URL to a fully native screen (Swift view
  controller / Kotlin fragment) instead of the web view.

## Reference index

All paths are relative to this skill's directory.

### Overview (platform-agnostic concepts)
- [Overview: How it Works](references/overview/how-it-works.md)
- [Overview: Basic Navigation](references/overview/basic-navigation.md)
- [Overview: Path Configuration](references/overview/path-configuration.md)
- [Overview: Bridge Components](references/overview/bridge-components.md)
- [Overview: Native Screens](references/overview/native-screens.md)

### iOS (Swift)
- [iOS: Getting Started](references/ios/getting-started.md)
- [iOS: Tabs](references/ios/tabs.md)
- [iOS: Path Configuration](references/ios/path-configuration.md)
- [iOS: Bridge Components](references/ios/bridge-components.md)
- [iOS: Native Screens](references/ios/native-screens.md)
- [iOS: Configuration (`Hotwire.config`)](references/ios/configuration.md)
- [iOS: Reference (Navigator, delegate, web view)](references/ios/reference.md)

### Android (Kotlin)
- [Android: Getting Started](references/android/getting-started.md)
- [Android: Tabs](references/android/tabs.md)
- [Android: Path Configuration](references/android/path-configuration.md)
- [Android: Bridge Components](references/android/bridge-components.md)
- [Android: Native Screens](references/android/native-screens.md)
- [Android: Configuration](references/android/configuration.md)
- [Android: Reference (Navigator, custom WebView, attributes)](references/android/reference.md)

### Shared reference
- [Reference: Navigation](references/reference/navigation.md)
- [Reference: Path Configuration](references/reference/path-configuration.md)
- [Reference: Bridge Installation](references/reference/bridge-installation.md)
- [Reference: Bridge Components](references/reference/bridge-components.md)

## Where to look for common tasks

| Task | Read |
| --- | --- |
| Create a new app | `references/<platform>/getting-started.md` |
| Add a native tab bar | `references/<platform>/tabs.md` |
| Route URLs to modals / native screens | `references/reference/path-configuration.md` (all properties) |
| Debug why a link opened a modal | `references/overview/basic-navigation.md`, `references/<platform>/path-configuration.md` |
| Build a bridge component end-to-end | `references/<platform>/bridge-components.md` + `references/reference/bridge-components.md` |
| Install the web-side bridge JS | `references/reference/bridge-installation.md` |
| Tune global settings | `references/ios/configuration.md` (iOS), `references/android/configuration.md` (Android) |
| Look up an API symbol | `references/<platform>/reference.md`, `references/reference/navigation.md` |

## Platforms & versions

- iOS package: `https://github.com/hotwired/hotwire-native-ios` (Swift Package),
  library product `HotwireNative`, minimum iOS 14.
- Android artifact: `dev.hotwire.hotwire-native-android` via Gradle.
- Web-side bridge JS: see [Bridge Installation](references/reference/bridge-installation.md).

## Working in an iOS project

If the project was scaffolded from the getting-started guide, it uses
`AppDelegate` + `SceneDelegate` with a `Navigator` created in `SceneDelegate`.
See `references/ios/getting-started.md` for the canonical setup.

`project.yml` + XcodeGen is a convenient way to define the project and its
Swift package dependency without the Xcode GUI; run `xcodegen generate` after
changing files or the manifest.

## Source

Documentation transcribed from <https://native.hotwired.dev>. Each reference
file records its original URL at the top. Community discussions and issues:
<https://github.com/hotwired/hotwire-native/discussions>.
