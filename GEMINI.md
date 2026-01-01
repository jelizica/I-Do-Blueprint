# GEMINI.md

## Project Overview

**"I Do Blueprint"** is a comprehensive wedding planning application for macOS, built with SwiftUI and backed by a Supabase backend. The application is designed to help users manage all aspects of their wedding planning, including budgets, guests, vendors, and more.

The project is characterized by a sophisticated and modern development process that heavily leverages AI-assisted development. It employs a suite of custom tools and a well-defined workflow to facilitate collaboration between human developers and AI agents.

### Key Technologies

*   **Frontend:** SwiftUI for the macOS application.
*   **Backend:** Supabase, used for the database, authentication, and serverless functions.
*   **Architecture:** The application follows a clean architecture that separates concerns into distinct layers:
    *   **UI:** SwiftUI views.
    *   **State Management:** A system of "stores" for managing application state, using a composition-over-inheritance approach.
    *   **Business Logic:** A "Domain Services" layer for encapsulating complex business rules.
    *   **Data Access:** A repository pattern for abstracting data sources.
*   **Development Tools:** The project uses a unique set of tools for its AI-driven development process:
    *   **Basic Memory:** A knowledge management system for creating a persistent, semantic knowledge base about the project.
    *   **Beads:** A git-backed issue tracker for managing tasks and dependencies.
    *   **MCP (Model Context Protocol) Servers:** A suite of specialized servers that provide AI coding assistants with various capabilities.
    *   **SwiftLint:** For enforcing a strict and consistent coding style.
*   **Security:** The project uses the `Themis` library for cryptographic operations.

## Building and Running

The project is a standard Xcode project.

**To Build:**

1.  Open `I Do Blueprint.xcodeproj` in Xcode.
2.  Select the "I Do Blueprint" scheme.
3.  Build the project (Cmd+B).

**To Run:**

1.  Open `I Do Blueprint.xcodeproj` in Xcode.
2.  Select the "I Do Blueprint" scheme.
3.  Run the project (Cmd+R).

### Command Line

The project can also be built and run from the command line:

```bash
# Resolve package dependencies
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies

# Build the project
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

### Configuration

The application uses hardcoded configuration for Supabase and Sentry in `I Do Blueprint/Core/Configuration/AppConfig.swift`. For development, these values can be overridden by creating a `Config.plist` file in the `I Do Blueprint/` directory with the following keys:

*   `SUPABASE_URL`
*   `SUPABASE_ANON_KEY`
*   `SENTRY_DSN`
*   `RESEND_API_KEY`

## Development Conventions

### AI-Driven Development

The project has a unique and highly structured AI-driven development workflow. This workflow is centered around two key tools:

*   **Basic Memory:** Used for long-term knowledge management. Architectural decisions, design patterns, and other important information are stored here.
*   **Beads:** Used for short-term task tracking. Features, bugs, and other work items are managed as "beads".

The general workflow is:

1.  **Research:** Use `Basic Memory` to understand the existing architecture and patterns.
2.  **Plan:** Create `Beads` to represent the work to be done.
3.  **Execute:** Work on the `Beads`, updating their status as you go.
4.  **Document:** Once the work is complete, document any new knowledge in `Basic Memory`.

For more details, see `BASIC-MEMORY-AND-BEADS-GUIDE.md`.

### Coding Style

The project uses SwiftLint to enforce a consistent coding style. The configuration can be found in `.swiftlint.yml`. Key aspects of the coding style include:

*   **Design System:** The project has a design system that is enforced through custom SwiftLint rules. Developers are expected to use tokens for colors, fonts, and spacing rather than hardcoded values.
*   **Pragmatism:** Many of the default SwiftLint rules are disabled to better suit the project's idiomatic style.

### Architecture

The application's architecture is designed to be clean, testable, and maintainable. Key architectural patterns include:

*   **Repository Pattern:** Used to abstract data sources.
*   **Domain Services:** Used to encapsulate complex business logic.
*   **Stores:** Used for state management, following a composition-over-inheritance model.
*   **Dependency Injection:** Used throughout the application to facilitate testing.

For more details on the architecture, see `docs/DOMAIN_SERVICES_ARCHITECTURE.md`.
