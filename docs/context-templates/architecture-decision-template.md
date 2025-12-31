# Architecture Decision Context Template

**Last Updated**: [Auto-update timestamp]

---

## Decision Overview

**ADR Number**: [If creating new ADR]
**Decision Title**: [Clear, concise title]
**Status**: [Proposed / Accepted / Deprecated / Superseded]
**Date**: [Decision date]

### Decision Statement
[One-sentence summary of the decision]

---

## Context

### Problem Statement
[What problem are we trying to solve? Why is this decision needed?]

### Current State
[Describe the current architecture/implementation]

### Constraints
- **Technical**: [Technical limitations]
- **Business**: [Business requirements]
- **Timeline**: [Time constraints]
- **Resources**: [Team/budget constraints]
- **Compliance**: [Security/privacy requirements]

### Stakeholders
- **Primary**: [Who is most affected]
- **Secondary**: [Who else cares]
- **Decision Makers**: [Who approves]

---

## Research Conducted

### Similar Patterns in Codebase
[Search Basic Memory for existing patterns]

```bash
mcp__basic-memory__search_notes("similar pattern", project: "i-do-blueprint")
```

**Findings**:
- [Pattern 1]: [How it's used, pros/cons]
- [Pattern 2]: [How it's used, pros/cons]

### External Research

#### Industry Best Practices
- [Source 1]: [Key takeaway]
- [Source 2]: [Key takeaway]
- [Source 3]: [Key takeaway]

#### Framework Documentation
- [Framework]: [Relevant guidance]
- [Library]: [Relevant guidance]

#### Community Insights
- [Blog post / Article]: [Summary]
- [GitHub discussion]: [Summary]

---

## Options Considered

### Option 1: [Name]

**Description**: [Detailed description]

**Pros**:
- ✅ [Advantage 1]
- ✅ [Advantage 2]
- ✅ [Advantage 3]

**Cons**:
- ❌ [Disadvantage 1]
- ❌ [Disadvantage 2]
- ❌ [Disadvantage 3]

**Implementation Effort**: [Low / Medium / High]
**Maintenance Burden**: [Low / Medium / High]
**Risk Level**: [Low / Medium / High]

**Code Example**:
```swift
// Illustrative example of this approach
```

### Option 2: [Name]

**Description**: [Detailed description]

**Pros**:
- ✅ [Advantage 1]
- ✅ [Advantage 2]
- ✅ [Advantage 3]

**Cons**:
- ❌ [Disadvantage 1]
- ❌ [Disadvantage 2]
- ❌ [Disadvantage 3]

**Implementation Effort**: [Low / Medium / High]
**Maintenance Burden**: [Low / Medium / High]
**Risk Level**: [Low / Medium / High]

**Code Example**:
```swift
// Illustrative example of this approach
```

### Option 3: [Name]

**Description**: [Detailed description]

**Pros**:
- ✅ [Advantage 1]
- ✅ [Advantage 2]
- ✅ [Advantage 3]

**Cons**:
- ❌ [Disadvantage 1]
- ❌ [Disadvantage 2]
- ❌ [Disadvantage 3]

**Implementation Effort**: [Low / Medium / High]
**Maintenance Burden**: [Low / Medium / High]
**Risk Level**: [Low / Medium / High]

**Code Example**:
```swift
// Illustrative example of this approach
```

---

## Decision Matrix

| Criteria | Weight | Option 1 | Option 2 | Option 3 |
|----------|--------|----------|----------|----------|
| Maintainability | 30% | 8/10 | 6/10 | 7/10 |
| Performance | 20% | 7/10 | 9/10 | 6/10 |
| Testability | 20% | 9/10 | 7/10 | 8/10 |
| Implementation Cost | 15% | 6/10 | 8/10 | 7/10 |
| Team Familiarity | 15% | 8/10 | 5/10 | 9/10 |
| **Weighted Score** | | **X.X** | **X.X** | **X.X** |

---

## Recommended Decision

### Selected Option: [Option Name]

**Rationale**:
[Explain why this option was chosen over the others]

**Key Factors**:
1. [Factor 1 that tipped the scales]
2. [Factor 2 that tipped the scales]
3. [Factor 3 that tipped the scales]

**Trade-offs Accepted**:
- [Trade-off 1]: [Why it's acceptable]
- [Trade-off 2]: [Why it's acceptable]

---

## Implementation Plan

### Phase 1: Foundation
**Timeline**: [Duration]
**Tasks**:
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

**Deliverables**:
- [Deliverable 1]
- [Deliverable 2]

### Phase 2: Core Implementation
**Timeline**: [Duration]
**Tasks**:
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

**Deliverables**:
- [Deliverable 1]
- [Deliverable 2]

### Phase 3: Migration & Rollout
**Timeline**: [Duration]
**Tasks**:
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

**Deliverables**:
- [Deliverable 1]
- [Deliverable 2]

---

## Impact Analysis

### Affected Components
```
Domain/
├── Models/[Feature]/
├── Repositories/
│   ├── Protocols/
│   └── Live/
└── Services/

Services/
└── Stores/[Feature]StoreV2.swift

Views/
└── [Feature]/
```

### Breaking Changes
- [ ] API changes
- [ ] Database schema changes
- [ ] Configuration changes
- [ ] Dependency updates

### Migration Path
[If breaking changes, describe how to migrate existing code]

### Rollback Plan
[How to revert if this decision proves problematic]

---

## Consequences

### Positive Consequences
- ✅ [Benefit 1]
- ✅ [Benefit 2]
- ✅ [Benefit 3]

### Negative Consequences
- ⚠️ [Drawback 1]: [Mitigation strategy]
- ⚠️ [Drawback 2]: [Mitigation strategy]
- ⚠️ [Drawback 3]: [Mitigation strategy]

### Neutral Consequences
- ℹ️ [Change 1]
- ℹ️ [Change 2]

---

## Validation Criteria

### Success Metrics
- [ ] [Metric 1]: [Target value]
- [ ] [Metric 2]: [Target value]
- [ ] [Metric 3]: [Target value]

### Testing Requirements
- [ ] Unit tests for new components
- [ ] Integration tests for data flow
- [ ] Performance benchmarks
- [ ] Security audit
- [ ] Accessibility compliance

### Review Checkpoints
- [ ] Week 1: Foundation review
- [ ] Week 2: Core implementation review
- [ ] Week 4: Migration review
- [ ] Week 6: Post-deployment review

---

## Documentation Requirements

### Code Documentation
- [ ] Inline comments for complex logic
- [ ] DocStrings for public APIs
- [ ] MARK comments for organization
- [ ] README updates

### Architecture Documentation
- [ ] Create/update ADR
- [ ] Update architecture diagrams
- [ ] Update ARCHITECTURE.md
- [ ] Update best_practices.md

### Knowledge Management
- [ ] Create Basic Memory note
- [ ] Update relevant patterns
- [ ] Document common pitfalls
- [ ] Create troubleshooting guide

### Team Communication
- [ ] Present to team
- [ ] Update onboarding docs
- [ ] Create migration guide
- [ ] Schedule knowledge sharing session

---

## Related Decisions

### Supersedes
- [ADR-XXX]: [Title] - [Why it's being replaced]

### Superseded By
- [If this decision is later replaced]

### Related To
- [ADR-XXX]: [Title] - [How they relate]
- [ADR-XXX]: [Title] - [How they relate]

### Depends On
- [ADR-XXX]: [Title] - [Dependency relationship]

---

## References

### Internal Resources
- [Basic Memory note]: [URL or path]
- [Existing ADR]: [URL or path]
- [Code example]: [File path]

### External Resources
- [Article]: [URL]
- [Documentation]: [URL]
- [Research paper]: [URL]
- [GitHub discussion]: [URL]

### Team Discussions
- [Meeting notes]: [Date and summary]
- [Slack thread]: [Link and summary]
- [Email thread]: [Date and summary]

---

## Review & Approval

### Reviewers
- [ ] [Name] - [Role] - [Date]
- [ ] [Name] - [Role] - [Date]
- [ ] [Name] - [Role] - [Date]

### Approval
- [ ] Technical Lead: [Name] - [Date]
- [ ] Product Owner: [Name] - [Date]
- [ ] Security Review: [Name] - [Date]

### Feedback Incorporated
- [Reviewer]: [Feedback] → [How addressed]
- [Reviewer]: [Feedback] → [How addressed]

---

## Post-Implementation Review

### Date: [Review date]

### What Worked Well
- [Success 1]
- [Success 2]
- [Success 3]

### What Didn't Work
- [Issue 1]: [How we adapted]
- [Issue 2]: [How we adapted]

### Lessons Learned
- [Lesson 1]
- [Lesson 2]
- [Lesson 3]

### Would We Decide Differently?
[Reflection on whether this was the right decision]

### Recommendations for Future
- [Recommendation 1]
- [Recommendation 2]

---

## Appendix

### Prototype Code
```swift
// If a prototype was built, include key snippets
```

### Performance Benchmarks
```
Benchmark results:
- Metric 1: [Before] → [After]
- Metric 2: [Before] → [After]
```

### Security Analysis
[Any security considerations or audit results]

### Accessibility Impact
[How this affects accessibility]

---

**Template Version**: 1.0
**Created By**: [Name]
**Last Updated By**: [Name]
