# LLM Council Prompt - Expense Categories Static Header Design

> **Purpose:** Deliberate on the optimal static header design for the Expense Categories page  
> **Target:** Pass to another AI agent with LLM Council MCP access  
> **Expected Output:** Consensus recommendation on static header layout and content

---

## Instructions for LLM Council Agent

Please use the LLM Council to deliberate on the best design for the **Expense Categories Static Header**. Query multiple AI models (GPT, Claude, Gemini, Grok) and synthesize their recommendations into a final design decision.

---

## Context

### Application Overview

**I Do Blueprint** is a macOS SwiftUI wedding planning application. The **Expense Categories** page manages budget categories in a hierarchical parent/subcategory structure. Users can:
- View all budget categories organized by parent/child relationships
- Search for specific categories
- Add, edit, delete, and duplicate categories
- See budget allocation and spending per category
- Track utilization percentages with progress bars

### Page Purpose

The Expense Categories page helps couples:
1. **Organize their budget** into logical categories (e.g., Venue, Catering, Photography)
2. **Track spending** against allocated amounts per category
3. **Manage subcategories** for detailed budget breakdown
4. **Identify problem areas** where spending exceeds allocation

### Data Available

The page has access to the following data:
- **Total categories count** (e.g., 36 total)
- **Parent categories count** (e.g., 11 parents)
- **Subcategories count** (e.g., 25 subcategories)
- **Total allocated budget** (sum of all category allocations)
- **Total spent** (sum of all category spending)
- **Categories over budget** (count of categories where spent > allocated)
- **Categories under budget** (count of categories where spent < allocated)
- **Unused categories** (categories with $0 allocated)
- **Individual category data** (name, allocated, spent, utilization %)

### Existing Static Header Patterns

Two other budget pages have static headers that we should consider for consistency:

#### 1. Expense Tracker Static Header
**Design:** Two-row budget health dashboard
- **Row 1:** Wedding countdown + Quick actions (Add Expense, Export)
- **Row 2:** Budget health metrics (spent/budget, status indicator, overdue badge, pending amount, per-guest cost)

**Key Features:**
- Clickable overdue badge that filters to overdue items
- Budget health status with color coding (On Track/Attention/Over Budget)
- Progress bar showing percentage spent
- Per-guest cost with toggle (Total/Attending/Confirmed)

#### 2. Payment Schedule Static Header
**Design:** Search + Next Payment Context
- **Search bar** (full-width in compact, constrained in regular)
- **Next payment info** (vendor name, amount, days until due)
- **Overdue badge** (clickable, filters to overdue payments)

**Key Features:**
- Simpler design focused on search and urgency
- Contextual "next item" information
- Clickable badge for quick filtering

### Design Constraints

1. **Responsive:** Must work at 640px (compact) and 900px+ (regular) widths
2. **Static:** Header should NOT scroll with content
3. **Consistent:** Should feel like part of the same app as other budget pages
4. **Actionable:** Elements should provide value, not just display data
5. **Compact-friendly:** Must not overflow or clip in narrow windows

### Visual Layout Requirements

**Regular Mode (≥700px):**
- Horizontal layout with elements spread across the width
- Search bar should be constrained (not full-width)
- Stats/metrics can be displayed inline

**Compact Mode (<700px):**
- Vertical stacking of elements
- Search bar should be full-width
- Stats should be condensed or abbreviated

---

## Design Question

**What should the Expense Categories static header contain and how should it be laid out?**

Consider:
1. **Search functionality** - Is search valuable for this page? (Users search by category name)
2. **Summary statistics** - What metrics are most useful at a glance?
3. **Actionable elements** - What should be clickable/interactive?
4. **Visual hierarchy** - What's most important to show first?
5. **Consistency** - How does this relate to Expense Tracker and Payment Schedule headers?

---

## Proposed Options to Evaluate

### Option A: Search + Category Stats
```
Regular:
┌─────────────────────────────────────────────────────────────────────┐
│ [🔍 Search categories...    ]     📁 11 Parents  📄 25 Subcategories │
└─────────────────────────────────────────────────────────────────────┘

Compact:
┌─────────────────────────────────┐
│ [🔍 Search categories...      ] │
│ 📁 11 Parents • 📄 25 Subcats   │
└─────────────────────────────────┘
```

**Pros:** Simple, focused on navigation
**Cons:** Doesn't show budget health information

### Option B: Search + Budget Health Summary
```
Regular:
┌─────────────────────────────────────────────────────────────────────────────┐
│ [🔍 Search...]   $45K / $50K allocated   ⚠️ 3 over budget   ✓ 8 on track   │
└─────────────────────────────────────────────────────────────────────────────┘

Compact:
┌─────────────────────────────────┐
│ [🔍 Search categories...      ] │
│ $45K/$50K • ⚠️3 over • ✓8 ok   │
└─────────────────────────────────┘
```

**Pros:** Shows budget health at category level
**Cons:** May duplicate info from summary cards below

### Option C: Search + Problem Categories Alert
```
Regular:
┌─────────────────────────────────────────────────────────────────────────────┐
│ [🔍 Search...]     ⚠️ 3 categories over budget (click to filter)    [+ Add] │
└─────────────────────────────────────────────────────────────────────────────┘

Compact:
┌─────────────────────────────────┐
│ [🔍 Search categories...      ] │
│ ⚠️ 3 over budget        [+ Add] │
└─────────────────────────────────┘
```

**Pros:** Actionable, highlights problems, includes quick add
**Cons:** Less informative when no problems exist

### Option D: Minimal Search Only
```
Regular:
┌─────────────────────────────────────────────────────────────────────────────┐
│ [🔍 Search categories...                                                  ] │
└─────────────────────────────────────────────────────────────────────────────┘

Compact:
┌─────────────────────────────────┐
│ [🔍 Search categories...      ] │
└─────────────────────────────────┘
```

**Pros:** Clean, simple, lets summary cards do the heavy lifting
**Cons:** May feel incomplete compared to other pages

### Option E: Category Health Dashboard (Similar to Expense Tracker)
```
Regular:
┌─────────────────────────────────────────────────────────────────────────────┐
│ [🔍 Search...]  │  📁 11 Parents  │  ⚠️ 3 Over  │  ✓ 8 On Track  │  [+ Add] │
└─────────────────────────────────────────────────────────────────────────────┘

Compact:
┌────────────���────────────────────┐
│ [🔍 Search categories...      ] │
│ 📁11 • ⚠️3 over • ✓8 ok  [+]   │
└─────────────────────────────────┘
```

**Pros:** Comprehensive, consistent with Expense Tracker approach
**Cons:** May be too busy for a simpler page

---

## Questions for the Council

1. **Which option provides the best balance of information and simplicity?**
2. **Should the "over budget" badge be clickable to filter categories?**
3. **Should there be an "Add Category" button in the static header?**
4. **What metrics are most valuable for category management?**
5. **How should this header differ from Expense Tracker's more complex dashboard?**

---

## Expected Output Format

Please provide:
1. **Consensus recommendation** - Which option (or hybrid) is best
2. **Rationale** - Why this design was chosen
3. **Layout specification** - Exact layout for both compact and regular modes
4. **Interactive elements** - What should be clickable and what happens on click
5. **Data requirements** - What data the header needs from the store

---

## Additional Context

### Summary Cards (Below Static Header)

The page will also have summary cards (similar to Budget Overview) showing:
- **Total Categories** (count)
- **Total Allocated** (sum of allocations)
- **Total Spent** (sum of spending)
- **Categories Over Budget** (count with warning color)

This means the static header doesn't need to duplicate all this information - it should complement the summary cards, not repeat them.

### User Workflow

Typical user actions on this page:
1. **Browse categories** - Scroll through parent/subcategory hierarchy
2. **Search for specific category** - Find a category by name
3. **Check problem areas** - Identify categories over budget
4. **Add new category** - Create a new parent or subcategory
5. **Edit category** - Modify allocation, name, or parent

The static header should support the most common workflows without cluttering the interface.

---

**End of Prompt**

Please run this through the LLM Council and return the consensus recommendation.
