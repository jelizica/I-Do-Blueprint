# Architectural Decision Records (ADRs)

This directory contains Architectural Decision Records (ADRs) for I Do Blueprint. ADRs document significant architectural decisions made during the development of the application.

## What is an ADR?

An ADR is a document that captures an important architectural decision made along with its context and consequences. ADRs help:
- Understand why decisions were made
- Onboard new team members
- Avoid repeating past mistakes
- Track architectural evolution
- Facilitate discussions about changes

## ADR Format

Each ADR follows this structure:
- **Status**: Proposed | Accepted | Deprecated | Superseded
- **Context**: Why this decision was needed
- **Decision**: What was decided
- **Consequences**: Positive and negative outcomes

## Index of ADRs

### Active ADRs

| Number | Title | Status | Date |
|--------|-------|--------|------|
| [ADR-001](ADR-001-repository-pattern-with-domain-services.md) | Repository Pattern with Domain Services Architecture | Accepted | 2025-12-29 |
| [ADR-002](ADR-002-multi-tenant-security-with-supabase-rls.md) | Multi-tenant Security with Supabase RLS | Accepted | 2025-12-29 |
| [ADR-003](ADR-003-v2-store-pattern-and-state-management.md) | V2 Store Pattern and State Management | Accepted | 2025-12-29 |
| [ADR-004](ADR-004-cache-invalidation-strategy-pattern.md) | Cache Invalidation Strategy Pattern | Accepted | 2025-12-29 |
| [ADR-005](ADR-005-timezone-aware-date-handling.md) | Timezone-Aware Date Handling | Accepted | 2025-12-29 |
| [ADR-006](ADR-006-error-handling-and-sentry-integration.md) | Error Handling and Sentry Integration | Accepted | 2025-12-29 |

## ADR Categories

### Architecture & Patterns
- ADR-001: Repository Pattern with Domain Services
- ADR-003: V2 Store Pattern and State Management
- ADR-004: Cache Invalidation Strategy Pattern

### Security
- ADR-002: Multi-tenant Security with Supabase RLS

### Data & State Management
- ADR-003: V2 Store Pattern and State Management
- ADR-004: Cache Invalidation Strategy Pattern
- ADR-005: Timezone-Aware Date Handling

### Error Handling & Monitoring
- ADR-006: Error Handling and Sentry Integration

## Creating a New ADR

1. Copy the template below
2. Number it sequentially (ADR-007, ADR-008, etc.)
3. Fill in all sections
4. Submit for review
5. Update this index

### ADR Template

```markdown
# ADR-XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
[Why this decision was needed. What problem are we solving?]

## Decision
[What was decided. Be specific and concrete.]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Drawback 1]
- [Drawback 2]

## Implementation Notes
[Practical guidance for implementing this decision]

## Related Documents
- [Link to related documentation]
```

## Superseding an ADR

When an ADR is superseded:
1. Update the old ADR's status to "Superseded by ADR-XXX"
2. Create a new ADR explaining the new decision
3. Reference the old ADR in the new one
4. Update this index

## Related Documentation

- [best_practices.md](../../best_practices.md) - Project best practices
- [ARCHITECTURE_IMPROVEMENT_PLAN.md](../../ARCHITECTURE_IMPROVEMENT_PLAN.md) - Architecture roadmap
- [CACHE_ARCHITECTURE.md](../CACHE_ARCHITECTURE.md) - Cache architecture details
- [DOMAIN_SERVICES_ARCHITECTURE.md](../DOMAIN_SERVICES_ARCHITECTURE.md) - Domain services details
- [TIMEZONE_SUPPORT.md](../TIMEZONE_SUPPORT.md) - Timezone handling details
