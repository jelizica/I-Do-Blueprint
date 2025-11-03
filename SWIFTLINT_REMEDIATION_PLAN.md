# SwiftLint Remediation Plan
## Remaining 2,098 Violations - Categorized Action Plan

**Status:** All 9 critical (error-level) violations resolved ✅  
**Remaining:** 2,098 warning-level violations  
**Goal:** Systematic cleanup to enable `--strict` mode

---

## Executive Summary

| Category | Count | Effort | Priority | Auto-Fix | Manual |
|----------|-------|--------|----------|----------|--------|
| **Enum Raw Values** | 674 | Medium | High | ❌ | ✅ |
| **File Organization** | 222 | Low | Medium | ❌ | ✅ |
| **Closure Syntax** | 205 | Low | Low | ❌ | ✅ |
| **Attributes** | 174 | Low | Medium | ✅ | ❌ |
| **Line Length** | ~300 | Medium | Medium | ❌ | ✅ |
| **Whitespace** | 65 | Low | High | ✅ | ❌ |
| **Naming** | 65 | Low | Medium | ❌ | ✅ |
| **Optional Booleans** | 24 | Medium | High | ❌ | ✅ |
| **Implicit Init** | 23 | Low | Low | ✅ | ❌ |
| **For-Where** | 19 | Low | Medium | ❌ | ✅ |
| **Unused Parameters** | 17 | Low | Low | ✅ | ❌ |
| **Trailing Items** | 29 | Low | Low | ✅ | ❌ |
| **Implicit Returns** | 11 | Low | Low | ❌ | ✅ |
| **Array Init** | 9 | Low | Low | ❌ | ✅ |
| **Other** | ~261 | Varies | Low | Mixed | Mixed |

**Total Auto-Fixable:** ~350 violations (17%)  
**Total Manual:** ~1,748 violations (83%)

---

## Phase 1: Quick Wins (Auto-Fixable) - 1-2 hours
**Impact:** ~350 violations (-17%)

### 1.1 Run SwiftLint Autocorrect
```bash
swiftlint autocorrect --format --config .swiftlint.yml
```

**Will automatically fix:**
- ✅ Trailing whitespace (38)
- ✅ Trailing newlines (15)
- ✅ Trailing commas (14)
- ✅ Vertical whitespace (12)
- ✅ Colon spacing (35)
- ✅ Unused closure parameters (17) - replaces with `_`
- ✅ Implicit optional initialization (23) - removes `= nil`
- ✅ Some attribute placements (139)
- ✅ Array init (9) - converts `seq.map { $0 }` to `Array(seq)`

**Estimated reduction:** 300-350 violations

**Action Items:**
1. Run autocorrect
2. Review changes with `git diff`
3. Build and test
4. Commit: "chore: apply SwiftLint autocorrect fixes"

---

## Phase 2: Enum Raw Values - 2-3 days
**Impact:** 674 violations (-32%)

### 2.1 Problem
Enums without explicit raw values violate `explicit_enum_raw_value` rule.

```swift
// ❌ Bad
enum Status: String {
    case pending
    case approved
    case rejected
}

// ✅ Good
enum Status: String {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}
```

### 2.2 Strategy
**Automated approach using script:**

```bash
# Find all enum violations
swiftlint --config .swiftlint.yml 2>&1 | \
  grep "explicit_enum_raw_value" | \
  awk -F: '{print $1":"$2}' | \
  sort -u > enum_violations.txt

# Process each file
while read line; do
  file=$(echo $line | cut -d: -f1)
  echo "Processing: $file"
  # Manual review and fix
done < enum_violations.txt
```

### 2.3 Action Items
1. **Day 1:** Fix Domain/Models/ enums (~200 violations)
   - Budget enums
   - Guest enums
   - Vendor enums
   - Task enums

2. **Day 2:** Fix Services/ and Core/ enums (~300 violations)
   - Store enums
   - Error enums
   - Configuration enums

3. **Day 3:** Fix Views/ and remaining enums (~174 violations)
   - UI state enums
   - Navigation enums
   - Validation enums

**Commit strategy:** One commit per feature area
- "fix(models): add explicit raw values to domain model enums"
- "fix(services): add explicit raw values to service enums"
- "fix(views): add explicit raw values to view enums"

---

## Phase 3: File Organization - 1 day
**Impact:** 222 violations (-11%)

### 3.1 Problem
`file_types_order` requires main type before supporting types.

```swift
// ❌ Bad
struct Helper { }  // Supporting type first
class MainClass { }  // Main type second

// ✅ Good
class MainClass { }  // Main type first
struct Helper { }  // Supporting type second
```

### 3.2 Strategy
**Semi-automated approach:**

```bash
# Find all file_types_order violations
swiftlint --config .swiftlint.yml 2>&1 | \
  grep "file_types_order" | \
  awk -F: '{print $1}' | \
  sort -u > file_order_violations.txt
```

### 3.3 Action Items
1. **Morning:** Fix 100 files in Domain/ and Services/
2. **Afternoon:** Fix 122 files in Views/ and Core/

**Pattern:**
- Move main type (class/struct with file name) to top
- Move extensions to bottom
- Move helper types to middle

**Commit:** "refactor: reorder types to comply with file_types_order rule"

---

## Phase 4: Line Length - 2-3 days
**Impact:** ~300 violations (-14%)

### 4.1 Problem
Lines exceeding 120 characters (warning threshold).

### 4.2 Strategy by Type

**A. Long function calls (most common):**
```swift
// ❌ Bad
let result = repository.fetchData(param1: value1, param2: value2, param3: value3, param4: value4)

// ✅ Good
let result = repository.fetchData(
    param1: value1,
    param2: value2,
    param3: value3,
    param4: value4
)
```

**B. Long strings:**
```swift
// ❌ Bad
let message = "This is a very long error message that exceeds the line length limit and should be broken up"

// ✅ Good
let message = """
    This is a very long error message that exceeds the line length limit \
    and should be broken up
    """
```

**C. Long conditionals:**
```swift
// ❌ Bad
if condition1 && condition2 && condition3 && condition4 && condition5 {

// ✅ Good
if condition1 
    && condition2 
    && condition3 
    && condition4 
    && condition5 {
```

**D. Long chains:**
```swift
// ❌ Bad
let result = data.filter { $0.isValid }.map { $0.value }.compactMap { $0.property }.sorted()

// ✅ Good
let result = data
    .filter { $0.isValid }
    .map { $0.value }
    .compactMap { $0.property }
    .sorted()
```

### 4.3 Action Items
1. **Day 1:** Fix Domain/ and Services/ (~150 violations)
2. **Day 2:** Fix Views/ (~100 violations)
3. **Day 3:** Fix Core/ and remaining (~50 violations)

**Commit strategy:** One commit per directory
- "style(domain): break long lines in domain layer"
- "style(services): break long lines in services layer"
- "style(views): break long lines in views layer"

---

## Phase 5: Naming Conventions - 1 day
**Impact:** 65 violations (-3%)

### 5.1 Problem
Single-letter variable names (r, g, b, i) violate `identifier_name` rule.

### 5.2 Strategy

**A. Color components (r, g, b):**
```swift
// ❌ Bad
let r = color.redComponent
let g = color.greenComponent
let b = color.blueComponent

// ✅ Good
let red = color.redComponent
let green = color.greenComponent
let blue = color.blueComponent
```

**B. Loop indices (i, j):**
```swift
// ❌ Bad
for i in 0..<count {
    items[i].process()
}

// ✅ Good
for index in 0..<count {
    items[index].process()
}

// OR use enumerated()
for (index, item) in items.enumerated() {
    item.process()
}
```

### 5.3 Action Items
1. **Morning:** Fix color-related naming (~38 violations in Design/ and Utilities/)
2. **Afternoon:** Fix loop indices (~27 violations across codebase)

**Commit:** "refactor: use descriptive variable names instead of single letters"

---

## Phase 6: Closure Syntax - 2 days
**Impact:** 205 violations (-10%)

### 6.1 Problem
`multiple_closures_with_trailing_closure` warns against trailing closure with multiple closures.

```swift
// ❌ Bad
UIView.animate(withDuration: 0.3) {
    view.alpha = 0
} completion: { _ in
    view.removeFromSuperview()
}

// ✅ Good
UIView.animate(
    withDuration: 0.3,
    animations: {
        view.alpha = 0
    },
    completion: { _ in
        view.removeFromSuperview()
    }
)
```

### 6.2 Action Items
1. **Day 1:** Fix Views/ (~150 violations)
2. **Day 2:** Fix Services/ and remaining (~55 violations)

**Note:** This is a style preference. Consider adding to `.swiftlint.yml` disabled rules if team prefers trailing closure syntax.

**Commit:** "style: use explicit closure labels for multiple closures"

---

## Phase 7: Optional Booleans - 1 day
**Impact:** 24 violations (-1%)

### 7.1 Problem
`discouraged_optional_boolean` warns against `Bool?` types.

```swift
// ❌ Bad
var isEnabled: Bool?

// ✅ Good - Option 1: Non-optional with default
var isEnabled: Bool = false

// ✅ Good - Option 2: Tri-state enum
enum EnabledState {
    case enabled
    case disabled
    case unknown
}
var enabledState: EnabledState = .unknown
```

### 7.2 Strategy
Review each case individually:
- If truly tri-state (yes/no/unknown), use enum
- If can have default, use non-optional Bool
- If genuinely optional (rare), add `// swiftlint:disable:next discouraged_optional_boolean` with comment explaining why

### 7.3 Action Items
1. Audit all 24 occurrences
2. Refactor to non-optional or enum
3. Document any exceptions

**Commit:** "refactor: replace optional booleans with non-optional or tri-state enums"

---

## Phase 8: For-Where Clauses - 1 hour
**Impact:** 19 violations (-1%)

### 8.1 Problem
`for_where` prefers `where` clause over `if` inside `for`.

```swift
// ❌ Bad
for item in items {
    if item.isValid {
        process(item)
    }
}

// ✅ Good
for item in items where item.isValid {
    process(item)
}
```

### 8.2 Action Items
1. Find all violations: `swiftlint | grep for_where`
2. Replace with `where` clause
3. Test and commit

**Commit:** "style: use where clauses in for loops"

---

## Phase 9: Implicit Returns - 1 hour
**Impact:** 11 violations (-0.5%)

### 9.1 Problem
`implicit_return` prefers omitting `return` in single-expression closures.

```swift
// ❌ Bad
let doubled = numbers.map { number in
    return number * 2
}

// ✅ Good
let doubled = numbers.map { number in
    number * 2
}
```

### 9.2 Action Items
1. Find violations
2. Remove explicit `return` keywords
3. Commit

**Commit:** "style: use implicit returns in single-expression closures"

---

## Phase 10: Remaining Issues - 1-2 days
**Impact:** ~261 violations (-12%)

### 10.1 Categories
- Custom design token rules (if any remain)
- Nesting violations
- Function parameter count
- Other opt-in rules

### 10.2 Strategy
1. Generate detailed report: `swiftlint --reporter json > violations.json`
2. Group by rule type
3. Address systematically

---

## Implementation Timeline

### Week 1: Foundation (Auto-fixes + Enums)
- **Day 1:** Phase 1 (Auto-fixes) - 2 hours
- **Day 2-4:** Phase 2 (Enum raw values) - 3 days
- **Day 5:** Phase 3 (File organization) - 1 day

**Expected reduction:** ~1,250 violations (60%)

### Week 2: Formatting & Style
- **Day 1-3:** Phase 4 (Line length) - 3 days
- **Day 4:** Phase 5 (Naming) - 1 day
- **Day 5:** Phase 6 (Closures) - Day 1 of 2

**Expected reduction:** ~570 violations (27%)

### Week 3: Polish & Completion
- **Day 1:** Phase 6 (Closures) - Day 2 of 2
- **Day 2:** Phase 7 (Optional booleans) - 1 day
- **Day 3:** Phases 8-9 (Quick fixes) - 2 hours
- **Day 4-5:** Phase 10 (Remaining) - 2 days

**Expected reduction:** ~278 violations (13%)

---

## Success Metrics

### Milestones
- ✅ **Milestone 1:** Zero critical violations (COMPLETE)
- 🎯 **Milestone 2:** Under 1,000 violations (after Week 1)
- 🎯 **Milestone 3:** Under 500 violations (after Week 2)
- 🎯 **Milestone 4:** Under 100 violations (after Week 3)
- 🎯 **Milestone 5:** Enable `--strict` mode

### Quality Gates
- ✅ Build succeeds after each phase
- ✅ All tests pass after each phase
- ✅ No behavior changes
- ✅ No API changes
- ✅ Git history is clean (meaningful commits)

---

## Risk Mitigation

### Risks
1. **Breaking changes:** Refactoring could introduce bugs
2. **Merge conflicts:** Long-running branches
3. **Team disruption:** Large diffs affect ongoing work

### Mitigation Strategies
1. **Small commits:** One phase at a time
2. **Comprehensive testing:** Run full test suite after each phase
3. **Code review:** All changes reviewed before merge
4. **Feature flags:** Use for risky changes
5. **Rollback plan:** Each phase is independently revertible

---

## Alternative Approach: Incremental

If 3-week timeline is too aggressive, use **incremental approach**:

### Option A: New Code Only
- Enable `--strict` mode for new files only
- Add `.swiftlint.yml` exclusions for existing files
- Clean up existing files opportunistically

### Option B: Module by Module
- Week 1: Domain layer
- Week 2: Services layer
- Week 3: Views layer
- Week 4: Core/Utilities

### Option C: Rule by Rule
- Week 1: Auto-fixable rules only
- Week 2: Enum raw values
- Week 3: File organization + line length
- Week 4+: Remaining rules as time permits

---

## Recommendation

**Recommended Approach:** Hybrid

1. **Immediate (This week):**
   - Phase 1: Auto-fixes (2 hours) ✅
   - Phase 8-9: Quick manual fixes (2 hours) ✅
   - **Result:** ~370 violations fixed, ~1,728 remaining

2. **Short-term (Next 2 weeks):**
   - Phase 2: Enum raw values (3 days)
   - Phase 3: File organization (1 day)
   - **Result:** ~900 violations fixed, ~828 remaining

3. **Medium-term (Following 2 weeks):**
   - Phase 4: Line length (3 days)
   - Phase 5: Naming (1 day)
   - **Result:** ~365 violations fixed, ~463 remaining

4. **Long-term (As time permits):**
   - Phases 6-7, 10: Remaining violations
   - **Result:** Enable `--strict` mode

**Total estimated effort:** 15-20 days spread over 4-6 weeks

---

## Next Steps

1. **Review this plan** with team
2. **Prioritize phases** based on team preferences
3. **Create Linear issues** for each phase
4. **Assign ownership** for each phase
5. **Schedule work** into sprints
6. **Execute Phase 1** (auto-fixes) immediately

---

## Appendix: SwiftLint Configuration Options

### Option 1: Disable Controversial Rules
If team disagrees with certain rules, disable them:

```yaml
disabled_rules:
  - multiple_closures_with_trailing_closure  # Team prefers trailing closure
  - implicit_return  # Team prefers explicit returns
```

### Option 2: Adjust Thresholds
Make rules less strict:

```yaml
line_length:
  warning: 140  # Increase from 120
  error: 180    # Increase from 160
```

### Option 3: Exclude Specific Files
Exclude generated or legacy code:

```yaml
excluded:
  - "I Do Blueprint/Legacy/**"
  - "I Do Blueprint/Generated/**"
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Status:** Ready for Review  
**Owner:** Engineering Team
