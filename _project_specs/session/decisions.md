<!--
LOG DECISIONS WHEN:
- Choosing between architectural approaches
- Selecting libraries or tools
- Making security-related choices
- Deviating from standard patterns

This is append-only. Never delete entries.
-->

# Decision Log

Track key architectural and implementation decisions.

## Format
```
## [YYYY-MM-DD] Decision Title

**Decision**: What was decided
**Context**: Why this decision was needed
**Options Considered**: What alternatives existed
**Choice**: Which option was chosen
**Reasoning**: Why this choice was made
**Trade-offs**: What we gave up
**References**: Related code/docs
```

---

## [2025-12-29] Claude Skills Setup for Swift/macOS Project

**Decision**: Use Swift-specific skill alongside generic skills
**Context**: Needed to add Claude coding guardrails to existing Swift/macOS project
**Options Considered**:
- Use generic skills only
- Create Swift-specific skill
- Use iOS skill (if available)
**Choice**: Created custom swift-macos.md skill
**Reasoning**: Swift has unique concurrency model, macOS has specific patterns (security-scoped resources, menu commands), generic skills insufficient
**Trade-offs**: Custom skill requires maintenance but provides better project-specific guidance
**References**: .claude/skills/swift-macos.md
