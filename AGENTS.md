# Repository Guidelines

## Project Structure & Module Organization
- Open `marketmate.xcodeproj` to view targets; core app code lives in `marketmate/`.
- Key folders: `Views/` (SwiftUI screens), `ViewModels/` (state + bindings), `Models/` (data types), `Services/` (network/local APIs), `DesignSystem/` (shared styles), `Utils/` and `Helpers/` (common utilities), `Assets.xcassets` (images/colors), and `marketmate.xcdatamodeld` (Core Data model).
- Tests reside in `marketmateTests/` (unit) and `marketmateUITests/` (UI flows). Keep new assets and fixtures grouped with the feature they support.

## Build, Test, and Development Commands
- Open in Xcode: `open marketmate.xcodeproj`.
- Build (CLI): `xcodebuild -scheme marketmate -destination "platform=iOS Simulator,name=iPhone 15" build`.
- Run all tests: `xcodebuild -scheme marketmate -destination "platform=iOS Simulator,name=iPhone 15" test`.
- Use Xcode’s Preview canvas for rapid UI iteration; keep previews lightweight and deterministic.

## Coding Style & Naming Conventions
- Swift style: 4-space indentation, limit line length to ~120 where possible, prefer `struct` for value types and `final class` for reference-bound view models.
- Naming: PascalCase for types and views (`HomeView`), camelCase for properties/methods (`loadOffers()`), uppercase snake for static constants when needed.
- Keep views declarative; push side effects into services/view models. Favor dependency injection over singletons.
- Run Xcode’s “Format” before committing; avoid ad-hoc reordering imports to preserve diffs.

## Testing Guidelines
- Framework: XCTest for unit and UI tests.
- Naming: mirror source paths (e.g., `ViewModels/HomeViewModelTests.swift`) and use `test_<behavior>_<expectedResult>()`.
- Add focused UI tests for primary flows (login, listing, checkout); stub network/services to keep runs deterministic.
- Gate new features with at least one behavioral test; prefer given/when/then comments for clarity.

## Commit & Pull Request Guidelines
- Commits in this repo use short, imperative summaries (e.g., `Additions`, `App edit`); follow that style and keep messages under ~60 chars.
- PRs should include: concise description of change, screenshots/video for UI updates, notes on testing performed (`xcodebuild … test` command and devices), and any migration steps.
- Link to relevant issues/tasks; call out risk areas (data model changes, breaking API updates) and rollback steps when applicable.

## Security & Configuration Tips
- Do not commit secrets or API keys; keep them in local keychain or `.xcconfig` ignored by git.
- Review `Info.plist` changes carefully—only add capabilities/entitlements that are required for shipped features.
