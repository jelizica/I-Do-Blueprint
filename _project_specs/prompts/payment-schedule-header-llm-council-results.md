# Payment Schedule Static Header Design - LLM Council Results

**Date:** 2026-01-02
**Status:** Stage 1 Complete (4 frontier models consulted)
**Context:** Designing the static header bar for Payment Schedule page

---

## Executive Summary

The LLM Council was consulted on designing a static header bar for the Payment Schedule page in I Do Blueprint. After codebase investigation revealed that payment schedules are **NOT tied to budget scenarios**, the council provided creative recommendations that adapt or justify breaking the established "dropdown + search" pattern from other Budget pages.

### Key Finding from Codebase Investigation

**Payment schedules are GLOBAL and NOT scenario-aware:**
- No `scenario_id` field in PaymentSchedule model
- Optional link to expenses via `expense_id: UUID?`
- Track real-world vendor contracts independent of budget planning
- Multi-tenant isolation via `couple_id` only

**Data Relationship:**
```
BudgetScenario (planning tool)
    ↓ (NO DIRECT LINK)
Expense (actual spending)
    ↓ (expense_id - OPTIONAL)
PaymentSchedule (payment tracking - GLOBAL)
```

---

## Current Page Structure

```
[Unified Header: "Budget" + "Payment Schedule" subtitle + ellipsis menu + nav dropdown]
↓
[??? STATIC HEADER BAR - TO BE DESIGNED ???] ← This is what we're designing
↓
[Stats Cards: Upcoming Payments | Overdue Payments | Total Schedules]
↓
[Filter Bar: Individual/Plans toggle + All/Upcoming/Overdue filter + Grouping]
↓
[Content: Payment list or Payment plans]
```

---

## Existing Patterns in Budget Section

**Budget Builder & Budget Overview:**
- Scenario Dropdown + Search Bar
- Layout: Vertical (compact 640px) / Horizontal (regular 900px+)

**Expense Tracker:**
- Category Filter Dropdown + Search Bar
- Same layout pattern

**Challenge:** Payment Schedule doesn't use scenarios OR categories, so what should the dropdown be?

---

## LLM Council Stage 1 Results (Round 2 - With Codebase Context)

### Agent 1: OpenAI GPT-5.1
**Recommendation:** **Vendor Filter + Search**

**Design:**
- **Dropdown:** Vendor filter (All Vendors + individual vendors from payment schedules)
- **Search:** Vendor name, notes, amounts

**Rationale:**
- Maintains "dropdown + search" pattern by replacing scenario with vendor
- Vendor is the natural "who" dimension for payments (analogous to Category in Expense Tracker)
- No duplication with filter bar (which handles time/status)
- Filters stats cards and content below

**Layout:**
- Compact (640px): Vertical stack (dropdown above search)
- Regular (900px+): Horizontal row (dropdown ~240px left, search right)

**Implementation:** Low complexity (~1 hour)

---

### Agent 2: Google Gemini 3 Pro
**Recommendation:** **View Mode Toggle + Search** (MOST CREATIVE)

**Design:**
- **Toggle/Dropdown:** Individual Payments | Payment Plans (promoted from filter bar)
- **Search:** Vendor, notes, payment details

**Rationale:**
- View mode is the "scenario equivalent" - it fundamentally changes data structure
- Differentiates "how I view data" (header) from "filtering data" (filter bar)
- Removes redundant toggle from filter bar below
- Maintains pattern consistency with "major scope selector + search"

**Layout:**
- Compact (640px): Search bar top, segmented control below
- Regular (900px+): Toggle/dropdown left (~200px), search right

**Key Insight:** "The 'Scenario Dropdown' serves a cognitive function: it defines the *structure* of the data users are looking at. In Payment Schedule, the only switch that fundamental is Individual vs Plans."

**Implementation:** Low complexity (~45 minutes)

---

### Agent 3: Anthropic Claude Sonnet 4.5
**Recommendation:** **Search Only (with evolution path)**

**Design (MVP):**
- **Search bar only** - prominent, full-width
- No dropdown

**Rationale:**
- "Pattern evolution over pattern compliance"
- Forcing a meaningless dropdown is "cargo culting"
- Search handles 80% of use cases
- Payment Schedule is fundamentally different (global, not scenario-scoped)
- Stats cards + filter bar already handle status/date

**Layout:**
- Compact (640px): Full-width search (44pt height)
- Regular (900px+): Centered search bar (max 600px for elegance)

**Evolution Path:**
- Phase 1 (MVP): Search only
- Phase 2: Add View Mode Toggle if user data shows need
- Phase 3: Add Expense Link filter for power users

**Counter-argument to consistency:**
"Pattern consistency should serve users, not designers. Users won't be confused by a search-only header—they'll appreciate the clarity."

**Implementation:** Low complexity (~30 minutes)

**Alternative Creative Options:**
1. **Vendor Filter + Search** (if pattern must be maintained)
2. **Expense Link Filter + Search** (surfaces data quality: "Linked to Expenses" vs "Standalone Payments")

---

### Agent 4: X.AI Grok 4
**Recommendation:** **Vendor Filter + Search** (same as GPT-5.1)

**Design:**
- **Dropdown:** Vendor filter with counts (e.g., "Florist A (3 payments)")
- **Search:** Vendors, notes, amounts
- Optional: Badges for vendors with overdue payments (red dot)

**Rationale:**
- Maintains "dropdown + search" pattern
- Vendor is core to payment obligations (contracts, invoices)
- Similar to Expense Tracker's category filter
- Context-aware: In Plans view, include "Grouped Plans" option

**Layout:**
- Compact (640px): Vertical (dropdown full-width top, search below)
- Regular (900px+): Horizontal (dropdown ~250px left, search expanding right)

**Implementation:** Low complexity (~1 hour)

---

## Creative Alternative Ideas (From Council)

### Option: Expense Link Filter + Search
**From:** Claude Sonnet 4.5 (Agent 5 persona)

**Design:**
- **Dropdown:** "All Payments" | "Linked to Expenses" | "Standalone Payments"
- **Search:** Standard search

**Rationale:**
- Surfaces meaningful data partition based on `expense_id` field
- Helps with budget reconciliation ("Which payments are accounted for?")
- Identifies data completeness gaps ("Which payments need expense entries?")

**Use case:** Advanced users who want to ensure all payments are properly tracked in budget

---

### Option: Smart Context Header (Too Complex)
**From:** Claude Sonnet 4.5 (Agent 4 persona)

**Design:**
- Adaptive header that changes based on state
- Default: Vendor filter + Search
- When filters active: Filter summary chip + Search
- When overdue exist: Overdue indicator + Search

**Assessment:** "Probably too clever" - might violate principle of least surprise

---

## Key Themes from Council

### 1. Pattern Adaptation Consensus
**3 out of 4 agents** want to maintain "dropdown + search" pattern:
- GPT-5.1: Vendor filter
- Gemini: View Mode toggle
- Grok: Vendor filter

**1 out of 4 agents** argues for intentional pattern break:
- Claude: Search-only (justified by unique data model)

### 2. Vendor as Natural Filter
**2 agents** explicitly chose vendor filter as the dropdown:
- Answers "who do I owe money to?"
- No overlap with existing filters (which handle time/status)
- Analogous to Category in Expense Tracker

### 3. View Mode Elevation
**2 agents** mentioned promoting Individual/Plans toggle:
- Gemini: Main recommendation (move from filter bar to header)
- Claude: Phase 2 enhancement option

### 4. Search is Essential
**All agents agree**: Search bar is mandatory and non-duplicative
- Search by vendor name, notes, amounts
- Highest-value feature regardless of dropdown choice

### 5. Justifiable Pattern Breaks
Claude's argument: "Consistency without purpose is cargo culting"
- Payment schedules are unique (global, not scenario-scoped)
- Forcing a dropdown for consistency alone creates bad UX
- Better to break pattern intentionally with clear justification

---

## The Pattern Consistency Debate

### FOR Maintaining Pattern (with adaptation):
**Arguments:**
- Users expect consistent structure across Budget section
- "Dropdown + search" is a learned mental model
- Vendor dropdown is analogous to Category (Expense Tracker)
- View Mode toggle is a "view scope selector" (like scenarios)
- Adaptation is better than rigid compliance

**Supporting Agents:** GPT-5.1, Gemini, Grok

### FOR Breaking Pattern (search-only):
**Arguments:**
- Payment schedules are fundamentally different (global data)
- Vendor filtering has low value (just search the vendor name)
- Expense filtering is confusing (many payments aren't linked)
- Stats cards + filter bar already provide comprehensive filtering
- Search-only provides clarity over forced consistency

**Supporting Agent:** Claude

---

## Implementation Complexity Summary

| Design Option | Complexity | Time Estimate |
|--------------|------------|---------------|
| **Search Only** | Low | ~30 minutes |
| **View Mode Toggle + Search** | Low | ~45 minutes |
| **Vendor Filter + Search** | Low | ~1 hour |
| **Expense Link Filter + Search** | Low | ~1 hour |
| **Smart Context Header** | Medium-High | Not recommended |

All viable options fit within the ~1.5 hour implementation constraint.

---

## Recommended Decision Framework

### Option 1: Vendor Filter + Search (GPT-5.1 / Grok consensus)
**Choose if:**
- Pattern consistency is high priority
- Users frequently need to filter by specific vendors
- You want to match Expense Tracker's pattern (category → vendor analogy)

**Pros:**
- Maintains established pattern
- Surfaces vendor dimension (not in filter bar)
- Feels familiar to Budget section users

**Cons:**
- Vendor list could grow long
- Search might handle vendor filtering adequately

---

### Option 2: View Mode Toggle + Search (Gemini - MOST CREATIVE)
**Choose if:**
- Individual/Plans switching is a frequent user action
- You want to simplify the filter bar
- Elevating view mode to header makes conceptual sense

**Pros:**
- Most impactful filter gets prominence
- Reduces filter bar complexity
- Maintains "control + search" pattern
- Data shows view switching is common

**Cons:**
- Technically duplicates functionality (though filter bar toggle would be removed)
- May not feel like a "scope selector" to all users

---

### Option 3: Search Only (Claude - MOST MINIMALIST)
**Choose if:**
- Simplicity and clarity are top priorities
- You're willing to evolve the pattern based on user feedback
- You want fastest implementation

**Pros:**
- Clearest, most focused interface
- No forced elements for pattern compliance
- Fast to implement and test
- Easy to enhance later

**Cons:**
- Breaks established Budget section pattern
- May feel "incomplete" to users familiar with other pages

---

## Additional Context for Decision-Making

### Current Filter Bar (would remain regardless of header choice):
- View mode toggle: Individual | Plans
- Status filter: All, Upcoming, Overdue, This Week, This Month, Paid
- Grouping (Plans view only): By Plan ID, By Expense, By Vendor

### Stats Cards (above filter bar):
- Upcoming Payments
- Overdue Payments
- Total Schedules

### User Mental Model for Payments:
- Primary questions: "Who do I owe?" (vendor), "When is it due?" (date), "Is it paid?" (status)
- Vendor and date are most important dimensions
- Date/status already well-covered in stats + filter bar
- Vendor dimension is NOT currently prominent

---

## Files for Implementation Reference

### Models:
- `Domain/Models/Budget/PaymentSchedule.swift` - Data model
  - `expenseId: UUID?` - Optional expense link
  - `vendorId: Int64?` - Optional vendor link
  - `paymentPlanId: UUID?` - Payment plan grouping
  - **NO scenario_id field**

### Stores:
- `Services/Stores/Budget/PaymentScheduleStore.swift` - State management

### Repositories:
- `Domain/Repositories/Live/Internal/PaymentScheduleDataSource.swift` - Data fetching
- Query for unique vendors: `SELECT DISTINCT vendor_id FROM payment_plans WHERE couple_id = ?`

### Views (for pattern reference):
- `Views/Budget/BudgetBuilderView.swift` - Scenario dropdown + search pattern
- `Views/Budget/ExpenseTrackerView.swift` - Category dropdown + search pattern

### Database:
- `supabase/migrations/20251227000003_create_payment_plan_summary_view.sql` - Payment plan view

---

## Next Steps

1. **Review all options** and choose based on your priorities (consistency vs. simplicity vs. creativity)

2. **If you choose Vendor Filter or View Mode Toggle:**
   - Implement dropdown/toggle component
   - Wire to existing store/repository
   - Test with multiple vendors/view modes

3. **If you choose Search Only:**
   - Implement prominent search bar
   - Add smart placeholder text
   - Plan for Phase 2 enhancements based on usage data

4. **Testing Checklist:**
   - Compact view (640px) - vertical layout works
   - Regular view (900px+) - horizontal layout works
   - Search functionality filters correctly
   - Dropdown (if applicable) filters stats cards + content
   - No duplication with filter bar
   - Matches design system (Typography, Spacing, AppColors)

---

## Personal Recommendation (From Investigation Agent)

Based on the council deliberation and codebase context, I lean toward **Gemini's View Mode Toggle + Search** for these reasons:

1. **Highest-impact filter:** Individual/Plans fundamentally changes the UI structure (flat list vs. grouped)
2. **Simplifies filter bar:** Removes redundant toggle below
3. **Maintains pattern:** Still has "control + search" structure
4. **Creative adaptation:** Respects the pattern without forcing irrelevant elements
5. **Quick implementation:** ~45 minutes, reuses existing toggle logic

However, if you want the absolute simplest solution, **Claude's Search Only** is compelling and defensible.

If pattern consistency is paramount, **Vendor Filter** (GPT-5.1/Grok) is the safest choice.

---

## Questions for Final Decision

1. **How important is strict pattern consistency** across all Budget pages?
2. **How frequently do users switch** between Individual and Plans views?
3. **Do you have analytics** on vendor filtering needs?
4. **Are you comfortable** breaking the pattern for good UX reasons?
5. **What's your timeline?** (All options fit ~1.5 hours, but search-only is fastest)

---

**Generated by:** LLM Council (GPT-5.1, Gemini 3 Pro, Claude Sonnet 4.5, Grok 4)
**Session ID:** 2026-01-02 Investigation + Council Stage 1
**Ready for:** Implementation decision
