🚀 Check out the guidelines [here](https://github.com/xcodeswift/contributors/blob/master/CHANGELOG_GUIDELINES.md)

## Next version

## 0.5.0

### Added
- SwiftShell as the main shell library - by @pepibumur

### Fixed
- Sake processes not getting killed when the execution was interrupted - by @pepibumur.


### Added
- Sake task to audit the Homebrew formula and execute it from the CI task https://github.com/xcodeswift/sake/pull/51 by @pepibumur.
- An `ask(message:)` method to ask for user input on the command line. https://github.com/xcodeswift/sake/pull/53 by @Dschee

## 0.3.0

### Added
- Console feedback when the project gets generated successfully https://github.com/xcodeswift/sake/pull/48 by @pepibumur.

### Changed
- Removed the need for a `utils` instance that gets passed around. Use `Utils` instead https://github.com/xcodeswift/sake/pull/41 by @yonaskolb.
- Changed the way Tasks are configured https://github.com/xcodeswift/sake/pull/42 by @yonaskolb.

### Fixed
- Right alignment when printing tasks https://github.com/xcodeswift/sake/pull/28 by @pepibumur.
- Xcode not being able to run Sake because there was no `main.swift` file https://github.com/xcodeswift/sake/pull/36 by @pepibumur.
- Update project dependencies to their latest versions. PathKit to 0.9.0, xcproj to 1.7.0 and Commander to 0.8.0
- Clean up extra linebreaks https://github.com/xcodeswift/sake/pull/46 by @pepibumur.

### Removed
- The need to call `run()` to execute the tasks https://github.com/xcodeswift/sake/pull/36 by @pepibumur.

### Added
- Throw an error when trying to register the same task more than once https://github.com/xcodeswift/sake/pull/29 by @pepibumur.
- It suggests an alternative task name when the user tries to execute a specific task and he misspells the task name https://github.com/xcodeswift/sake/pull/25 by @Juanpe.

## 0.2.0

### Added
- Extract utils into a separate library https://github.com/xcodeswift/sake/pull/10 by @pepibumur.
- Hooks https://github.com/xcodeswift/sake/pull/9 by @pepibumur
- Xcode project generation https://github.com/xcodeswift/sake/pull/4 by @pepibumur.
- Homebrew support https://github.com/xcodeswift/sake/pull/5 by @pepibumur.
