# Component Library Migration Guide

This guide helps you migrate existing custom components to use the unified component library.

## Quick Reference

### Replace Custom Empty States → UnifiedEmptyStateView
### Replace Custom Stats Cards → StatsCardView / StatsGridView
### Replace Custom Progress → CircularProgress / ProgressBar
### Replace Custom List Rows → StandardListRow
### Replace Custom Cards → InfoCard / ActionCard / SummaryCard
### Replace Custom Search → SearchBar
### Replace Custom Alerts → ErrorBannerView / InlineErrorView

---

## Migration Examples

### 1. Empty States

**Before:**
```swift
if items.isEmpty {
    VStack(spacing: 20) {
        Image(systemName: "tray")
            .font(.system(size: 60))
            .foregroundColor(.secondary)
        
        Text("No Items")
            .font(.title2)
            .fontWeight(.bold)
        
        Text("Add your first item to get started")
            .foregroundColor(.secondary)
        
        Button("Add Item") {
            showAddSheet = true
        }
        .buttonStyle(.borderedProminent)
    }
}
```

**After:**
```swift
if items.isEmpty {
    UnifiedEmptyStateView(config: .custom(
        icon: "tray",
        title: "No Items",
        message: "Add your first item to get started",
        actionTitle: "Add Item",
        onAction: { showAddSheet = true }
    ))
}
```

---

### 2. Progress Indicators

**Before (CircleProgressView):**
```swift
struct CircleProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}
```

**After:**
```swift
// Simply use CircularProgress from the component library
CircularProgress(
    value: progress,
    color: color,
    lineWidth: lineWidth,
    size: 80,
    showPercentage: true
)
```

---

### 3. Stats Cards

**Before (Custom CompactStatCard):**
```swift
struct CompactStatCard: View {
    let value: String
    let label: String
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
            
            Text(value)
                .font(.system(size: 42, weight: .bold))
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(20)
        .background(backgroundColor)
    }
}
```

**After:**
```swift
// Use CompactSummaryCard from the component library
CompactSummaryCard(
    title: label,
    value: value,
    icon: icon,
    color: backgroundColor
)

// Or use StatsCardView for more features
StatsCardView(
    stat: StatItem(
        icon: icon,
        label: label,
        value: value,
        color: backgroundColor
    )
)
```

---

### 4. List Rows

**Before:**
```swift
HStack(spacing: 16) {
    Circle()
        .fill(color.opacity(0.15))
        .frame(width: 40, height: 40)
        .overlay(
            Image(systemName: icon)
                .foregroundColor(color)
        )
    
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.headline)
        
        Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    Spacer()
    
    Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
}
.padding()
.background(Color(NSColor.controlBackgroundColor))
.cornerRadius(8)
```

**After:**
```swift
StandardListRow(
    icon: icon,
    iconColor: color,
    title: title,
    subtitle: subtitle,
    accessory: .chevron,
    action: { handleTap() }
)
```

---

### 5. Summary Cards

**Before:**
```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Overview")
        .font(.headline)
    
    Divider()
    
    HStack {
        Text("Total")
        Spacer()
        Text("\(total)")
            .fontWeight(.semibold)
    }
    
    HStack {
        Text("Completed")
        Spacer()
        Text("\(completed)")
            .fontWeight(.semibold)
    }
    
    HStack {
        Text("Pending")
        Spacer()
        Text("\(pending)")
            .fontWeight(.semibold)
    }
}
.padding()
.background(Color(NSColor.controlBackgroundColor))
.cornerRadius(12)
```

**After:**
```swift
SummaryCard(
    title: "Overview",
    items: [
        SummaryItem(label: "Total", value: "\(total)"),
        SummaryItem(label: "Completed", value: "\(completed)", icon: "checkmark.circle.fill", color: .green),
        SummaryItem(label: "Pending", value: "\(pending)", icon: "clock.fill", color: .orange)
    ]
)
```

---

### 6. Search Bars

**Before:**
```swift
HStack(spacing: 8) {
    Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
    
    TextField("Search...", text: $searchText)
        .textFieldStyle(.plain)
    
    if !searchText.isEmpty {
        Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
.background(Color(NSColor.controlBackgroundColor))
.cornerRadius(8)
```

**After:**
```swift
SearchBar(
    text: $searchText,
    placeholder: "Search...",
    onSubmit: { performSearch() }
)
```

---

### 7. Action Cards

**Before:**
```swift
VStack(alignment: .leading, spacing: 16) {
    Circle()
        .fill(color.opacity(0.15))
        .frame(width: 56, height: 56)
        .overlay(
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
        )
    
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.title3)
        
        Text(description)
            .font(.body)
            .foregroundColor(.secondary)
    }
    
    Button(action: action) {
        Text(buttonTitle)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
.padding()
.background(Color(NSColor.controlBackgroundColor))
.cornerRadius(12)
```

**After:**
```swift
ActionCard(
    icon: icon,
    title: title,
    description: description,
    buttonTitle: buttonTitle,
    color: color,
    action: action
)
```

---

### 8. Error/Success Messages

**Before:**
```swift
HStack {
    Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
        .foregroundColor(isError ? .red : .green)
    
    Text(message)
        .font(.body)
    
    Spacer()
    
    Button(action: onDismiss) {
        Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
    }
}
.padding()
.background((isError ? Color.red : Color.green).opacity(0.1))
.cornerRadius(8)
```

**After:**
```swift
// For banner-style messages
ErrorBannerView(
    message: message,
    onDismiss: onDismiss
)

// For inline messages
InlineErrorView(
    message: message,
    onRetry: onRetry
)
```

---

### 9. Progress Bars

**Before:**
```swift
GeometryReader { geometry in
    ZStack(alignment: .leading) {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 8)
        
        Rectangle()
            .fill(color)
            .frame(width: geometry.size.width * progress, height: 8)
    }
}
.frame(height: 8)
.cornerRadius(4)
```

**After:**
```swift
ProgressBar(
    value: progress,
    color: color,
    height: 8,
    showPercentage: true
)
```

---

### 10. List Sections

**Before:**
```swift
VStack(alignment: .leading, spacing: 12) {
    HStack {
        Text("Section Title")
            .font(.headline)
        
        Spacer()
        
        Button("Add") {
            showAddSheet = true
        }
    }
    
    Divider()
    
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
.padding()
.background(Color(NSColor.controlBackgroundColor))
.cornerRadius(12)
```

**After:**
```swift
CardListSection(
    title: "Section Title",
    action: ListHeader.ActionConfig(
        title: "Add",
        icon: "plus",
        handler: { showAddSheet = true }
    )
) {
    ForEach(items) { item in
        StandardListRow(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            accessory: .chevron
        )
    }
}
```

---

## Benefits of Migration

### 1. Consistency
- Unified design language across the app
- Predictable user experience
- Professional appearance

### 2. Maintainability
- Single source of truth for components
- Changes propagate automatically
- Easier to update and fix bugs

### 3. Accessibility
- Built-in VoiceOver support
- Proper semantic markup
- WCAG AA compliance

### 4. Development Speed
- Less code to write
- Reusable patterns
- Well-documented APIs

### 5. Quality
- Tested components
- Consistent behavior
- Fewer bugs

---

## Migration Checklist

- [ ] Identify custom components that match library components
- [ ] Replace one component at a time
- [ ] Test functionality after each replacement
- [ ] Verify accessibility with VoiceOver
- [ ] Check visual appearance in light/dark mode
- [ ] Update any dependent code
- [ ] Remove old custom component files
- [ ] Update documentation

---

## Common Patterns

### Dashboard Cards
Replace custom dashboard cards with `CompactSummaryCard` or `SummaryCard`

### Settings Rows
Replace custom settings rows with `StandardListRow` with `.toggle()` accessory

### Form Fields
Replace custom text fields with `ValidatedTextField`

### Empty States
Replace all custom empty states with `UnifiedEmptyStateView`

### Stats Displays
Replace custom stats with `StatsGridView` and factory methods

### Progress Indicators
Replace custom progress views with `CircularProgress` or `ProgressBar`

---

## Need Help?

1. Check the main README for component documentation
2. Review component preview code for examples
3. Look at already-migrated views for patterns
4. Consult the design system documentation

---

## Version History

### v1.0.0
- Initial migration guide
- Covers all major component types
- Includes before/after examples
