---
title: LLM Council Prompt - Payment Schedule Static Header Design
type: note
permalink: architecture/plans/llm-council-prompt-payment-schedule-static-header-design
tags:
- llm-council
- payment-schedule
- static-header
- ux-design
- decision-making
---

# LLM Council Prompt: Payment Schedule Static Header Design

> **Purpose:** Multi-agent deliberation on optimal static header design for Payment Schedule page  
> **Tool:** LLM Council (https://github.com/khuynh22/llm-council)  
> **Created:** January 2, 2026  
> **Decision Required:** Functionality and layout for static header bar

---

## How to Use This Prompt

1. **Install LLM Council MCP Server** (if not already installed)
2. **Copy the prompt below** into Claude Code or your MCP-enabled client
3. **Run through LLM Council** with multiple agents for diverse perspectives
4. **Review consensus** and dissenting opinions
5. **Make final decision** based on council recommendation
6. **Update implementation plan** with chosen design

---

## Prompt for LLM Council

```
# CONTEXT

You are designing a static header bar for the Payment Schedule page in a macOS wedding planning app (I Do Blueprint). This header will sit between the unified page header and the statistics cards.

## Project Background

**App:** I Do Blueprint - macOS SwiftUI wedding planning application  
**Tech Stack:** SwiftUI, Supabase backend, macOS 13.0+  
**Design System:** Established Typography, Spacing, AppColors tokens  
**Target Users:** Couples planning weddings, managing budgets and payments

## Current Payment Schedule Page Structure

```
[Unified Header: "Budget" + "Payment Schedule" subtitle + ellipsis menu + nav dropdown]
↓
[??? STATIC HEADER BAR - TO BE DESIGNED ???]
↓
[Stats Cards: Upcoming Payments | Overdue Payments | Total Schedules]
↓
[Filter Bar: Individual/Plans toggle + All/Upcoming/Overdue filter + Grouping]
↓
[Content: Payment list or Payment plans]
```

## Existing Patterns in Budget Section

### Budget Builder Page
**Static Header Contains:**
- **Scenario Dropdown:** Select active budget scenario
- **Search Bar:** Search budget items by name/vendor

**Layout:**
- Compact (640px): Vertical stack (dropdown above search)
- Regular (900px+): Horizontal row (dropdown left, search right)

### Budget Overview Page
**Static Header Contains:**
- **Scenario Dropdown:** Select active budget scenario  
- **Search Bar:** Search budget items

**Layout:**
- Same as Budget Builder (vertical compact, horizontal regular)

### Expense Tracker Page
**Static Header Contains:**
- **Category Filter:** Dropdown to filter by expense category
- **Search Bar:** Search expenses by name/vendor

**Layout:**
- Same pattern (vertical compact, horizontal regular)

## Payment Schedule Specific Context

**Data Model:**
- Individual payments with: vendor, amount, date, paid status, notes
- Payment plans: Multiple payments grouped by plan ID, expense, or vendor
- Filters: All, Upcoming, Overdue, This Week, This Month, Paid
- Grouping strategies: By Plan ID, By Expense, By Vendor

**User Actions:**
- Toggle paid/unpaid status
- Search payments by vendor or notes
- Filter by date range or status
- Switch between Individual and Plans view
- Group plans by different strategies

**Current Filter Bar (below stats cards):**
- View mode toggle: Individual | Plans
- Filter dropdown: All, Upcoming, Overdue, This Week, This Month, Paid
- Grouping dropdown (Plans view only): By Plan ID, By Expense, By Vendor

## Design Constraints

1. **Must work in compact (640px) and full-screen (1200px+) views**
2. **Must follow existing design system** (Typography, Spacing, AppColors)
3. **Must be static** (doesn't scroll with content)
4. **Should complement, not duplicate** existing filter bar functionality
5. **Should match patterns** from Budget Builder/Overview/Expense Tracker
6. **Must be useful** - not just decorative

## Questions for the Council

### Primary Question
**What functionality should the static header bar provide for Payment Schedule?**

### Options to Consider

**Option A: Scenario + Search (Match Budget Builder/Overview)**
- Scenario dropdown (if payment schedules support scenarios)
- Search bar for payments/vendors
- Pros: Consistent with other budget pages
- Cons: Payment schedules may not use scenarios

**Option B: Date Range + Search**
- Date range picker (This Week, This Month, Custom Range, All Time)
- Search bar for payments/vendors
- Pros: Date filtering is critical for payment schedules
- Cons: Overlaps with filter bar's date filters

**Option C: Quick Actions + Search**
- Quick action buttons (Add Payment, Export, View Settings)
- Search bar
- Pros: Fast access to common actions
- Cons: Actions already in ellipsis menu

**Option D: Search Only (Minimal)**
- Just a prominent search bar
- Pros: Simple, focused, no duplication
- Cons: May feel empty compared to other pages

**Option E: Smart Filters + Search**
- Smart filter chips (Overdue: 3, Due This Week: 5, Unpaid: 12)
- Search bar
- Pros: At-a-glance status, quick filtering
- Cons: Overlaps with stats cards and filter bar

**Option F: Timeline + Search**
- Timeline view toggle (List | Calendar | Timeline)
- Search bar
- Pros: Adds new visualization option
- Cons: Significant implementation complexity

**Option G: Custom Combination**
- Your own recommendation based on UX principles

### Secondary Questions

1. **Should the header duplicate any filter bar functionality?**
   - If yes, which filters are most important to promote?
   - If no, what unique value should it provide?

2. **How should the header adapt to compact vs. full-screen?**
   - Vertical stack vs. horizontal row?
   - Hide elements in compact?
   - Different element order?

3. **Should the header be context-aware?**
   - Show different content for Individual vs. Plans view?
   - Highlight overdue payments?
   - Show sync status?

4. **What's the information hierarchy?**
   - What's most important for users to access quickly?
   - What can wait for the filter bar or ellipsis menu?

## Deliberation Instructions

1. **Each agent should:**
   - Propose a specific design (Option A-G or custom)
   - Explain the UX rationale
   - Consider compact and full-screen layouts
   - Address potential drawbacks
   - Suggest implementation complexity (Low/Medium/High)

2. **Council should discuss:**
   - Consistency vs. page-specific optimization
   - Duplication vs. convenience
   - Simplicity vs. feature richness
   - User mental model and expectations

3. **Final recommendation should include:**
   - Chosen functionality (be specific)
   - Layout for compact view (640px)
   - Layout for regular/large view (900px+)
   - Rationale for decision
   - Implementation notes
   - Any dissenting opinions worth considering

## Output Format

Please provide:

1. **Individual Agent Proposals** (each agent's recommendation)
2. **Council Discussion** (key points of agreement/disagreement)
3. **Final Consensus** (specific design recommendation)
4. **Implementation Guidance** (layout specs, component structure)
5. **Dissenting Opinions** (if any agent strongly disagrees)

## Success Criteria

The recommended design should:
- ✅ Provide clear user value
- ✅ Work seamlessly in compact and full-screen views
- ✅ Follow established design patterns
- ✅ Not duplicate existing functionality unnecessarily
- ✅ Be implementable in ~1.5 hours
- ✅ Feel natural to users familiar with other budget pages

---

**Begin Council Deliberation**
```

---

## Expected Output Structure

The LLM Council should return something like:

```markdown
# LLM Council Decision: Payment Schedule Static Header

## Agent Proposals

### Agent 1 (UX Specialist)
**Recommendation:** Option B - Date Range + Search
**Rationale:** [...]
**Layout:** [...]
**Complexity:** Medium

### Agent 2 (Consistency Advocate)
**Recommendation:** Option A - Scenario + Search
**Rationale:** [...]
**Layout:** [...]
**Complexity:** Low

### Agent 3 (Minimalist)
**Recommendation:** Option D - Search Only
**Rationale:** [...]
**Layout:** [...]
**Complexity:** Low

## Council Discussion

**Key Points:**
- Consistency vs. page-specific needs
- Avoiding duplication with filter bar
- User expectations from other budget pages

**Areas of Agreement:**
- Search bar is essential
- Must work in compact view
- Should follow design system

**Areas of Disagreement:**
- Whether to include date range picker
- Whether to match other pages exactly

## Final Consensus

**Chosen Design:** [Specific recommendation]

**Functionality:**
- [Element 1]: [Description]
- [Element 2]: [Description]

**Compact Layout (640px):**
```
[Vertical stack description]
```

**Regular Layout (900px+):**
```
[Horizontal row description]
```

**Rationale:**
[Why this design was chosen]

**Implementation Notes:**
- Component name: PaymentScheduleStaticHeader
- Estimated complexity: [Low/Medium/High]
- Key considerations: [...]

## Dissenting Opinion

**Agent X disagrees because:**
[Reasoning for alternative approach]
```

---

## Next Steps After Council Decision

1. ✅ Review council recommendation
2. ✅ Make final decision (accept consensus or choose alternative)
3. ✅ Update implementation plan with specific design
4. ✅ Create Beads issue for Phase 3
5. ✅ Implement PaymentScheduleStaticHeader component
6. ✅ Test in compact and full-screen views
7. ✅ Commit and push

---

## Additional Context for Council

### User Workflow
1. User navigates to Payment Schedule
2. Sees overview stats (upcoming, overdue, total)
3. **[Uses static header for ??? ]**
4. Uses filter bar to refine view
5. Interacts with payment list/plans

### Pain Points to Address
- Finding specific payments quickly
- Understanding payment timeline at a glance
- Switching between different views/filters
- Accessing common actions efficiently

### Design System Tokens Available

**Typography:**
- `.title`, `.title2`, `.heading`, `.subheading`
- `.bodyRegular`, `.bodyMedium`, `.caption`

**Spacing:**
- `.xs` (4px), `.sm` (8px), `.md` (12px), `.lg` (16px), `.xl` (24px)

**Colors:**
- `AppColors.primary`, `.textPrimary`, `.textSecondary`
- `.success`, `.warning`, `.error`
- `Color(NSColor.controlBackgroundColor)` for backgrounds

---

**Last Updated:** January 2, 2026  
**Status:** Ready for LLM Council deliberation  
**Decision Deadline:** Before Phase 3 implementation