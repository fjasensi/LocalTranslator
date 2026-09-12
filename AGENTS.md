# Repository Guidelines

## Project Structure & Module Organization

LocalTranslator is a macOS Swift command-line application using Foundation, with no third-party package dependencies.

- `LocalTranslator/main.swift` contains the entry point, `Codable` request/response models, translation settings, and asynchronous HTTP calls. It checks for a loaded model before requesting a translation.
- `LocalTranslator.xcodeproj/` defines the `LocalTranslator` target and scheme, with Debug and Release configurations.
- There are currently no test directories or bundled assets. Add application source files under `LocalTranslator/`; keep generated build products outside the repository.

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

# Run after configuring LM Studio.
/tmp/LocalTranslator-build/Build/Products/Debug/LocalTranslator
```

Replace `Debug` with `Release` for an optimized build. No automated test command is configured.

## Coding Style & Naming Conventions

Use four-space indentation, braces on the declaration line, and multiline formatting for longer calls. Follow the existing `UpperCamelCase` type names, such as `ChatRequest`, and existing snake_case variable names, such as `model_name`. Preserve API field names such as `loaded_instances`, or map them explicitly with `CodingKeys` when renaming properties.

Prefer `let`, `Codable`, and `async`/`await`, consistent with the current implementation. No formatter or linter is configured; match surrounding code and avoid unrelated formatting changes.

## Testing Guidelines

There is no test framework, test target, or coverage threshold. For behavior changes, build and manually check successful translation, an unloaded model, and an unavailable server. Confirm successful output contains only the trimmed translation. Record the checks and observed results in the pull request. If adding automated tests, document their target, framework, and execution command.

## Commit & Pull Request Guidelines

The two existing commits use plain descriptive subjects, including `Initial Commit`; no structured convention is established. Write concise subjects describing the change. Pull requests should explain the behavior change, link relevant issues, and include build/manual verification results and console output when useful. Avoid unrelated `xcuserdata` or signing-setting changes.

## Local Configuration

Start LM Studio's local server at `http://127.0.0.1:1234` and load `qwen/qwen3-1.7b`. Model, endpoint, languages, and input text are constants in `main.swift`; adjust them for local experiments. Use nonsensitive sample text in committed changes.
