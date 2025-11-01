# WARP.md

Linting
- Local: `swiftlint --strict`
- CI: Uses Mint with a pinned SwiftLint version (see `Mintfile`) and runs `swiftlint --strict --reporter github-actions-logging`.
- Token enforcement rules are defined in `.swiftlint.yml` (tracked in JES-195).
