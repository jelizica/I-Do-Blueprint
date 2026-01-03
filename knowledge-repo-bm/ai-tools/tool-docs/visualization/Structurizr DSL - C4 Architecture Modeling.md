---
title: Structurizr DSL - C4 Architecture Modeling
type: note
permalink: ai-tools/visualization/structurizr-dsl-c4-architecture-modeling
---

# Structurizr DSL - C4 Architecture Modeling

> **Model-based C4 diagrams from a single source of truth**

## Overview

Structurizr DSL is a text-based domain-specific language for creating software architecture models based on the C4 model. Unlike traditional "diagrams as code" tools, Structurizr is **model-based**, enabling you to generate multiple diagrams at different levels of abstraction from a single source file. Created by Simon Brown (author of the C4 model), it ensures consistency across system context, container, component, and code diagrams.

**Agent Attachments:**
- ❌ Qodo Gen (standalone tool, CLI-based)
- ❌ Claude Code (standalone tool, CLI-based)
- ❌ Claude Desktop (standalone tool, CLI-based)
- ✅ **CLI/Shell** (agent-agnostic via Structurizr CLI)
- ✅ **Homebrew** (`brew install structurizr-cli`)

**I Do Blueprint Usage:**
- **Location**: `docs/architecture/workspace.dsl`
- **Export Script**: `./scripts/generate-diagrams.sh`
- **Output**: `docs/architecture/exports/*.png`
- **Purpose**: Comprehensive C4 model with 7 dynamic views

---

## Why Structurizr DSL?

### The C4 Model

C4 stands for **Context, Containers, Components, and Code** - a hierarchical approach to software architecture diagrams, like zooming in on Google Maps:

1. **System Context** (Level 1) - 10,000 ft view
   - Who uses the system?
   - What external systems does it interact with?
   - **Audience**: Everyone (executives, non-technical stakeholders)

2. **Container** (Level 2) - Application/Data Store level
   - What are the high-level technology choices?
   - How is the system decomposed?
   - **Audience**: Technical team, architects

3. **Component** (Level 3) - Code structure within containers
   - What are the key abstractions/components?
   - How do they interact?
   - **Audience**: Developers, architects

4. **Code** (Level 4) - Class/implementation details
   - Usually generated from code (UML, ERD)
   - Rarely created manually
   - **Audience**: Developers

### Model-Based vs. Diagram-Based

| Approach | Consistency | Reuse | Abstraction Levels | Tooling |
|----------|-------------|-------|-------------------|---------|
| **Mermaid/PlantUML** | ❌ Manual | ❌ Copy-paste | One diagram = one file | Many |
| **Structurizr DSL** | ✅ Automatic | ✅ Single model | Multiple views from one model | Structurizr CLI, Lite |

**Example Problem with Diagram-Based Tools:**
```
Context diagram: "User uses Software System"
Container diagram: "User uses Web Application"  ❌ Different name!
```

**Structurizr Solution:**
Define once, reference everywhere:
```dsl
user = person "User"
webapp = container "Web Application"
user -> webapp "Uses"
```
Both diagrams automatically show consistent naming.

---

## Installation

### Homebrew (macOS/Linux)

```bash
# Install Structurizr CLI
brew install structurizr-cli

# Verify installation
structurizr-cli --version
# Expected: Structurizr CLI v2025.11.09 or newer
```

### Manual Installation (All Platforms)

1. Download from: https://github.com/structurizr/cli/releases
2. Unzip to a directory
3. Add to PATH (optional)
4. Run with `./structurizr.sh` (Linux/macOS) or `structurizr.bat` (Windows)

### Docker

```bash
# Pull image
docker pull structurizr/cli:latest

# Run (mount current directory)
docker run -it --rm \
  -v $PWD:/usr/local/structurizr \
  structurizr/cli export \
  --workspace workspace.dsl \
  --format png
```

### Structurizr Lite (Optional UI)

```bash
# Run with Docker
docker run -it --rm \
  -p 8080:8080 \
  -v $PWD:/usr/local/structurizr \
  structurizr/lite

# Open browser
open http://localhost:8080
```

---

## Workspace Structure

### Basic Workspace Template

```dsl
workspace "Workspace Name" "Optional description" {
    
    model {
        // Define elements and relationships here
    }
    
    views {
        // Define diagrams here
    }
    
    configuration {
        // Optional configuration
    }
}
```

### Complete Example (I Do Blueprint)

```dsl
workspace "I Do Blueprint" "Wedding planning macOS app with Supabase backend" {

    model {
        // External Systems
        user = person "Couple" "Wedding planners organizing their event"
        googleSheets = softwareSystem "Google Sheets" "Budget tracking alternative" "External"
        sentry = softwareSystem "Sentry" "Error tracking and monitoring" "External"
        
        // Main System
        iDoBlueprint = softwareSystem "I Do Blueprint" "macOS wedding planning application" {
            
            // Containers (Applications & Data Stores)
            swiftUIApp = container "SwiftUI Application" "Native macOS app" "SwiftUI, Swift 6" {
                
                // Components (within SwiftUI App)
                viewLayer = component "View Layer" "SwiftUI views and UI components" "SwiftUI"
                storeLayer = component "Store Layer" "@MainActor observable objects" "Swift @MainActor"
                repositoryLayer = component "Repository Layer" "Async CRUD + caching" "Swift async/await"
                domainLayer = component "Domain Services" "Business logic aggregation" "Swift Actor"
                cacheLayer = component "Cache Strategy" "In-memory caching with invalidation" "Swift"
                
                // Relationships
                viewLayer -> storeLayer "Uses @Environment"
                storeLayer -> repositoryLayer "Calls via @Dependency"
                repositoryLayer -> cacheLayer "Checks cache"
                repositoryLayer -> domainLayer "Delegates complex logic"
            }
            
            supabase = container "Supabase Backend" "PostgreSQL database with RLS" "PostgreSQL" "Database"
            
            // Container relationships
            swiftUIApp -> supabase "Queries via Supabase Swift SDK"
            swiftUIApp -> sentry "Sends error reports"
        }
        
        // User relationships
        user -> iDoBlueprint "Plans wedding using"
        user -> googleSheets "Exports budget to"
    }
    
    views {
        // System Context Diagram
        systemContext iDoBlueprint "SystemContext" "System context for I Do Blueprint" {
            include *
            autolayout lr
        }
        
        // Container Diagram
        container iDoBlueprint "Containers" "Container view showing app + backend" {
            include *
            autolayout lr
        }
        
        // Component Diagram
        component swiftUIApp "Components" "Five-layer architecture" {
            include *
            autolayout tb
        }
        
        // Dynamic Views (Sequences)
        dynamic swiftUIApp "DataFlowRead" "User reads data from database" {
            viewLayer -> storeLayer "1. User loads view"
            storeLayer -> repositoryLayer "2. Call load method"
            repositoryLayer -> cacheLayer "3. Check cache"
            cacheLayer -> repositoryLayer "4. Cache miss"
            repositoryLayer -> supabase "5. Query database"
            supabase -> repositoryLayer "6. Return data"
            repositoryLayer -> cacheLayer "7. Update cache"
            repositoryLayer -> storeLayer "8. Return data"
            storeLayer -> viewLayer "9. Update @Published property"
            autolayout lr
        }
        
        // Styles
        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #FF6B6B
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
        
        themes https://static.structurizr.com/themes/default/theme.json
    }
}
```

---

## Language Reference

### 1. Model Elements

#### Person

Represents a user of the system:

```dsl
user = person "User" "A person who uses the system"
admin = person "Administrator" "System admin with elevated permissions" {
    tags "Critical"
}
```

#### Software System

High-level system boundary:

```dsl
mySystem = softwareSystem "My System" "Does something useful" {
    tags "Important"
}

externalSystem = softwareSystem "External API" "Third-party service" "External"
```

#### Container

Application or data store within a system:

```dsl
iDoBlueprint = softwareSystem "I Do Blueprint" {
    webapp = container "Web Application" "User interface" "React"
    api = container "API" "Business logic" "Node.js"
    db = container "Database" "Data storage" "PostgreSQL" "Database"
}
```

**Common Container Types:**
- Web Application (React, Vue, Angular)
- Mobile App (iOS, Android)
- Desktop App (Electron, native)
- API/Microservice
- Database (SQL, NoSQL)
- Message Queue (RabbitMQ, Kafka)
- File Storage (S3, Azure Blob)

#### Component

Code-level structure within a container:

```dsl
api = container "API" {
    controller = component "Event Controller" "Handles event requests" "Express.js"
    service = component "Event Service" "Business logic" "TypeScript"
    repository = component "Event Repository" "Data access" "TypeScript"
    
    controller -> service "Calls"
    service -> repository "Uses"
}
```

### 2. Relationships

#### Basic Relationship

```dsl
user -> system "Uses"
system -> database "Reads from and writes to"
```

#### Relationship with Technology

```dsl
webapp -> api "Makes API calls to" "HTTPS/REST"
api -> database "Queries" "SQL over TCP"
```

#### Relationship Tags

```dsl
system -> externalAPI "Integrates with" {
    tags "Async" "Critical"
}
```

### 3. Groups

Organize elements with visual boundaries:

```dsl
model {
    group "Frontend Team" {
        webapp = container "Web Application"
        mobileApp = container "Mobile App"
    }
    
    group "Backend Team" {
        api = container "API"
        database = container "Database"
    }
}
```

**Nested Groups:**
```dsl
group "Organization" {
    group "Department A" {
        system1 = softwareSystem "System 1"
    }
    group "Department B" {
        system2 = softwareSystem "System 2"
    }
}
```

### 4. Deployment Environments

Model infrastructure:

```dsl
model {
    // ... model elements ...
    
    deploymentEnvironment "Production" {
        deploymentNode "AWS" {
            deploymentNode "ECS Cluster" {
                containerInstance api
            }
            deploymentNode "RDS" {
                containerInstance database
            }
        }
    }
}
```

---

## Views Reference

### System Context View

Shows the system in its environment:

```dsl
views {
    systemContext mySystem "SystemContext" "High-level context" {
        include *
        autolayout lr
    }
}
```

**Include Patterns:**
- `include *` - All people and systems with direct relationships
- `include user` - Specific element
- `include element.property==value` - Conditional include

### Container View

Shows containers within a system:

```dsl
views {
    container mySystem "Containers" "Container diagram" {
        include *
        exclude relationship.tag==Internal
        autolayout tb
    }
}
```

### Component View

Shows components within a container:

```dsl
views {
    component apiContainer "Components" "API components" {
        include *
        autolayout lr
    }
}
```

### Dynamic Views (Sequence-like)

Show runtime interactions:

```dsl
views {
    dynamic swiftUIApp "UserLogin" "User authentication flow" {
        viewLayer -> storeLayer "1. User enters credentials"
        storeLayer -> repositoryLayer "2. Call authenticate()"
        repositoryLayer -> supabase "3. Verify credentials"
        supabase -> repositoryLayer "4. Return JWT token"
        repositoryLayer -> storeLayer "5. Store token"
        storeLayer -> viewLayer "6. Navigate to home"
        autolayout lr
    }
}
```

**Numbering:**
- Automatic: Steps numbered 1, 2, 3...
- Manual: Specify in relationship description

### Deployment Views

Show infrastructure:

```dsl
views {
    deployment mySystem "Production" "Prod" "Production deployment" {
        include *
        autolayout tb
    }
}
```

### Filtered Views

Create views with custom filters:

```dsl
views {
    filtered "Containers" include element.tag==Important {
        title "Important Containers Only"
    }
}
```

---

## AutoLayout

### Directions

```dsl
autolayout lr  // Left to Right
autolayout rl  // Right to Left
autolayout tb  // Top to Bottom
autolayout bt  // Bottom to Top
```

### Rank Separation

Control spacing between ranks:

```dsl
autolayout tb 100 100  // rankSeparation nodeSeparation
```

### Manual Layout Override

Disable autolayout to position manually:

```dsl
// No autolayout - positions set via Structurizr UI
systemContext mySystem {
    include *
    // User manually drags elements in Structurizr Lite
}
```

---

## Styling

### Element Styles

```dsl
styles {
    element "Person" {
        shape Person
        background #08427b
        color #ffffff
        fontSize 24
    }
    
    element "Software System" {
        background #1168bd
        color #ffffff
        shape RoundedBox
    }
    
    element "Database" {
        shape Cylinder
        background #FF6B6B
    }
    
    element "External" {
        background #999999
        border Dashed
    }
}
```

**Available Shapes:**
- Box (default)
- RoundedBox
- Circle
- Ellipse
- Hexagon
- Cylinder (for databases)
- Pipe (for messaging)
- Person
- Robot (for bots)
- Folder
- WebBrowser
- MobileDevicePortrait
- MobileDeviceLandscape

### Relationship Styles

```dsl
styles {
    relationship "Relationship" {
        thickness 2
        color #707070
        style solid
    }
    
    relationship "Async" {
        style dashed
        color #FF6B6B
    }
}
```

### Themes

Apply pre-built themes:

```dsl
views {
    themes https://static.structurizr.com/themes/default/theme.json
    themes https://static.structurizr.com/themes/amazon-web-services-2022.04.30/theme.json
}
```

**Popular Themes:**
- Default: `https://static.structurizr.com/themes/default/theme.json`
- AWS: `https://static.structurizr.com/themes/amazon-web-services-2022.04.30/theme.json`
- Azure: `https://static.structurizr.com/themes/microsoft-azure-2021.01.26/theme.json`
- Google Cloud: `https://static.structurizr.com/themes/google-cloud-platform-v1.5/theme.json`

### Custom Colors (I Do Blueprint)

```dsl
styles {
    element "ViewLayer" {
        background #90EE90  // Light green
        color #000000
    }
    element "StoreLayer" {
        background #87CEEB  // Sky blue
        color #000000
    }
    element "RepositoryLayer" {
        background #FFB6C1  // Light pink
        color #000000
    }
    element "DomainLayer" {
        background #F0E68C  // Khaki
        color #000000
    }
    element "Database" {
        background #FF6B6B  // Light red
        color #ffffff
        shape Cylinder
    }
}
```

---

## CLI Commands

### Export Diagrams

```bash
# Export all views as PNG
structurizr-cli export \
    --workspace workspace.dsl \
    --format png \
    --output exports/

# Export specific view
structurizr-cli export \
    --workspace workspace.dsl \
    --format png \
    --view SystemContext

# Export as Mermaid
structurizr-cli export \
    --workspace workspace.dsl \
    --format mermaid

# Export as PlantUML
structurizr-cli export \
    --workspace workspace.dsl \
    --format plantuml
```

**Available Formats:**
- `png` - PNG images (requires browser/Puppeteer)
- `plantuml` - PlantUML format
- `mermaid` - Mermaid diagrams
- `websequencediagrams` - WebSequenceDiagrams format
- `dot` - Graphviz DOT format
- `ilograph` - Ilograph YAML
- `json` - Structurizr JSON format

### Validate Workspace

```bash
# Check DSL syntax
structurizr-cli validate --workspace workspace.dsl
```

### Push/Pull to Structurizr Cloud

```bash
# Push to cloud workspace
structurizr-cli push \
    --workspace workspace.dsl \
    --id WORKSPACE_ID \
    --key API_KEY \
    --secret API_SECRET

# Pull from cloud
structurizr-cli pull \
    --workspace workspace.json \
    --id WORKSPACE_ID \
    --key API_KEY \
    --secret API_SECRET
```

---

## I Do Blueprint Implementation

### Workspace File Location

**File**: `docs/architecture/workspace.dsl`

**Key Sections:**
1. **Model**: 5 layers (View, Store, Repository, Domain, Supabase)
2. **Views**: 3 static (Context, Container, Component) + 4 dynamic (data flows)
3. **Styles**: Layer-specific colors matching five-layer architecture

### Generate Diagrams Script

**File**: `./scripts/generate-diagrams.sh`

```bash
#!/bin/bash

# I Do Blueprint - Generate Architecture Diagrams
# Exports all views from workspace.dsl as PNG files

PROJECT_ROOT="/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
WORKSPACE_FILE="$PROJECT_ROOT/docs/architecture/workspace.dsl"
OUTPUT_DIR="$PROJECT_ROOT/docs/architecture/exports"

# Validate workspace exists
if [ ! -f "$WORKSPACE_FILE" ]; then
    echo "Error: workspace.dsl not found at $WORKSPACE_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Export all views
echo "Exporting diagrams from workspace.dsl..."
structurizr-cli export \
    --workspace "$WORKSPACE_FILE" \
    --format png \
    --output "$OUTPUT_DIR"

# List generated files
echo ""
echo "Generated diagrams:"
ls -lh "$OUTPUT_DIR"/*.png

echo ""
echo "✅ Diagram export complete"
```

### Generated Diagram Files

**Location**: `docs/architecture/exports/`

| File | Purpose | Audience |
|------|---------|----------|
| `SystemContext-001.png` | High-level: Users + external systems | Executives, stakeholders |
| `Containers-001.png` | App + backend separation | Technical team |
| `Components-001.png` | Five-layer architecture | Developers, architects |
| `DataFlowRead-001.png` | User reads data | Developers |
| `DataFlowWrite-001.png` | User writes with cache invalidation | Developers |
| `CacheMiss-001.png` | Post-invalidation flow | Developers |
| `DomainServiceDelegation-001.png` | Repository → domain actor | Developers |

### Usage Workflow

1. **Edit Model**: Update `docs/architecture/workspace.dsl`
2. **Regenerate**: Run `./scripts/generate-diagrams.sh`
3. **Commit Both**: Commit `.dsl` source AND `.png` exports
4. **Review**: View diagrams in `exports/` folder

---

## Advanced Features

### Constants & String Substitution

```dsl
!const ORG_NAME "My Organization"
!const SYSTEM_NAME "My System"

workspace {
    model {
        system = softwareSystem "${ORG_NAME} - ${SYSTEM_NAME}"
    }
}
```

### Environment Variables

```bash
export DB_NAME="PostgreSQL"

# In workspace.dsl:
database = container "Database" "${DB_NAME}"
```

### Include External Files

```dsl
workspace {
    model {
        !include model/people.dsl
        !include model/systems.dsl
    }
    
    views {
        !include views/diagrams.dsl
    }
}
```

**Example `model/people.dsl`:**
```dsl
user = person "User"
admin = person "Administrator"
```

### Extending Existing Workspaces

```dsl
workspace extends https://example.com/base-workspace.json {
    model {
        // Add more elements to base workspace
        newSystem = softwareSystem "New System"
    }
}
```

### Implied Relationships

Automatic relationship creation:

```dsl
!impliedRelationships true

model {
    user = person "User"
    system = softwareSystem "System" {
        webapp = container "Web App"
    }
    
    user -> webapp "Uses"
    // Automatically creates: user -> system "Uses"
}
```

### Documentation

Attach Markdown/AsciiDoc:

```dsl
iDoBlueprint = softwareSystem "I Do Blueprint" {
    !docs docs/architecture/system
}

// docs/architecture/system/01-introduction.md
// docs/architecture/system/02-constraints.md
```

### Architecture Decision Records (ADRs)

```dsl
iDoBlueprint = softwareSystem "I Do Blueprint" {
    !adrs docs/architecture/adrs
}

// docs/architecture/adrs/0001-use-supabase.md
// docs/architecture/adrs/0002-cache-strategy.md
```

---

## Best Practices

### 1. Use Hierarchical Identifiers

```dsl
!identifiers hierarchical

model {
    iDoBlueprint = softwareSystem "I Do Blueprint" {
        webapp = container "Web App"
    }
    
    // Reference as: iDoBlueprint.webapp
}
```

### 2. Tag Everything

```dsl
webapp = container "Web Application" {
    tags "Frontend" "Critical"
}

api = container "API" {
    tags "Backend" "Critical"
}

// Apply styles to tags
styles {
    element "Critical" {
        background #FF0000
    }
}
```

### 3. Consistent Naming

**Good:**
```dsl
eventRepository = component "Event Repository"
guestRepository = component "Guest Repository"
```

**Bad:**
```dsl
eventsRepo = component "Repository for Events"
guests = component "Guest Data Access Layer"
```

### 4. One Workspace Per System

Don't mix multiple unrelated systems in one workspace:

```dsl
// ❌ Bad: Multiple systems in one workspace
workspace {
    system1 = softwareSystem "CRM"
    system2 = softwareSystem "Inventory"
    system3 = softwareSystem "Billing"
}

// ✅ Good: One workspace per system
workspace "CRM System" {
    crm = softwareSystem "CRM"
}
```

### 5. Version Control DSL Source

```bash
git add docs/architecture/workspace.dsl
git add docs/architecture/exports/*.png
git commit -m "docs: Update architecture diagrams for feature X"
```

---

## Troubleshooting

### Syntax Errors

**Problem**: Workspace won't parse

**Solution**: Run validation
```bash
structurizr-cli validate --workspace workspace.dsl
```

**Common Errors:**
- Missing closing braces `}`
- Duplicate element names
- Invalid relationship syntax (use `->` not `→`)

### Export Produces No Files

**Problem**: PNG export fails

**Solution**: Check workspace syntax first
```bash
# Validate
structurizr-cli validate --workspace workspace.dsl

# Export with verbose output
structurizr-cli export -workspace workspace.dsl -format png -output exports/ -v
```

### Diagrams Look Cluttered

**Problem**: Too many elements on one diagram

**Solution**: Use filtered views
```dsl
views {
    container mySystem "CoreContainers" {
        include element.tag==Core
        autolayout lr
    }
}
```

### Relationships Don't Show

**Problem**: Missing arrows in diagrams

**Solution**: Check relationship direction and scope
```dsl
// ❌ Bad: No relationship defined
user = person "User"
system = softwareSystem "System"

// ✅ Good: Relationship defined
user -> system "Uses"
```

---

## Resources

### Official Documentation

- **Website**: https://structurizr.com
- **DSL Docs**: https://docs.structurizr.com/dsl
- **Language Reference**: https://docs.structurizr.com/dsl/language
- **Tutorial**: https://docs.structurizr.com/dsl/tutorial
- **CLI Docs**: https://docs.structurizr.com/cli

### GitHub Repositories

- **DSL**: https://github.com/structurizr/dsl
- **CLI**: https://github.com/structurizr/cli
- **Examples**: https://github.com/structurizr/dsl/tree/master/examples

### C4 Model

- **C4 Model**: https://c4model.com
- **Simon Brown's Blog**: https://simonbrown.je
- **C4 Examples**: https://c4model.com/#examples

### Community

- **GitHub Discussions**: https://github.com/structurizr/dsl/discussions
- **Twitter**: @simonbrown

---

## Summary

Structurizr DSL is the **definitive tool for C4 model architecture diagrams**. It solves consistency problems inherent in diagram-based tools by using a single model as the source of truth. For I Do Blueprint, Structurizr generates 7 comprehensive views (context, containers, components, + 4 dynamic flows) from one `workspace.dsl` file, ensuring naming and relationships stay consistent across all abstraction levels.

**Key Strengths:**
- 🏗️ **Model-based** (one source, multiple views)
- 🎯 **C4 model native** (context → container → component)
- 🔄 **Consistency guaranteed** (no duplicate definitions)
- 📊 **Multiple abstractions** (executives to developers)
- 🚀 **CLI automation** (export PNG, Mermaid, PlantUML)
- 📝 **Version control friendly** (text-based DSL)

**Perfect For:**
- Comprehensive architecture documentation
- Multi-level stakeholder communication
- Systems with many containers/components
- Teams needing consistency enforcement
- Documentation that evolves with the codebase

**I Do Blueprint Usage:**
- `workspace.dsl` - Single source of truth
- 7 generated diagrams (3 static + 4 dynamic)
- Five-layer architecture visualization
- Automated export via `generate-diagrams.sh`

---

**Last Updated**: December 30, 2025  
**Version**: Structurizr CLI 2025.11.09  
**I Do Blueprint Integration**: Active