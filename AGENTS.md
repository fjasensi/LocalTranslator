# Repository Guidelines

## Project Structure & Module Organization

LocalTranslator is a macOS Swift menu bar application using AppKit, Carbon, and Foundation, with no third-party package dependencies.

- `LocalTranslator/main.swift` starts the accessory application.
- `LocalTranslator/AppDelegate.swift`, `GlobalHotKey.swift`, and `TranslatorViewController.swift` implement the status item, global ⌥T shortcut, popover UI, language direction selector, and translation actions.
- `LocalTranslator/LMStudioClient.swift` contains the Codable API models and asynchronous LM Studio client.
- `Resources/Assets.xcassets/` contains the generated application icon variants; `Info.plist` configures the menu bar-only bundle.
- `LocalTranslator.xcodeproj/` defines the `LocalTranslator` application target and scheme.

## Build, Test, and Development Commands

Use Xcode with an SDK supporting the project's macOS 26.5 deployment target. The project uses Swift 5 language mode.

Run commands from the repository root:

```sh
# Open the project in Xcode.
open LocalTranslator.xcodeproj

# Build a local Debug executable without signing.
xcodebuild -project LocalTranslator.xcodeproj -scheme LocalTranslator \
  -configuration Debug -derivedDataPath /tmp/LocalTranslator-build \
  CODE_SIGNING_ALLOWED=NO build

# Launch the menu bar app after configuring LM Studio.
open /tmp/LocalTranslator-build/Build/Products/Debug/LocalTranslator.app
```

Replace `Debug` with `Release` for an optimized build. The app appears in the menu bar and opens with ⌥T. No automated test command is configured.

## Coding Style & Naming Conventions

Use four-space indentation, braces on the declaration line, and multiline formatting for longer calls. Use `UpperCamelCase` for types (`ChatRequest`) and `lowerCamelCase` for variables, properties, and functions (`modelKey`, `isLoaded`). Preserve uppercase initialisms (`chatURL`). Preserve JSON keys with explicit `CodingKeys` mappings, such as `loadedInstances = "loaded_instances"`.

Prefer `let` and `async`/`await`. Use `Encodable` for request bodies, `Decodable` for responses, and `Codable` when both directions are needed. No formatter or linter is configured; match surrounding formatting and avoid unrelated changes.

## Testing Guidelines

There is no test framework, test target, or coverage threshold. For behavior changes, build and manually check opening from the menu bar and ⌥T, both language directions, successful translation, an unloaded model, and an unavailable server. Confirm successful output contains only the trimmed translation. Record the checks and observed results in the pull request. If adding automated tests, document their target, framework, and execution command.

## Commit & Pull Request Guidelines

Existing commits use plain descriptive subjects, including `Initial Commit`; no structured convention is established. Write concise subjects describing the change. Pull requests should explain the behavior change, link relevant issues, and include build/manual verification results and console output when useful. Avoid unrelated `xcuserdata` or signing-setting changes.

## Local Configuration

Start LM Studio's local server at `http://127.0.0.1:1234` and load `qwen/qwen3-1.7b`. The endpoint and model are configured in `AppDelegate.swift`; the active languages and text are selected in `TranslatorViewController.swift`. Use nonsensitive sample text in committed changes.
