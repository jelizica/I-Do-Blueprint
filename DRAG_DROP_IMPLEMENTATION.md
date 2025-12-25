# Robust Drag-and-Drop Implementation Plan

## Overview
This document outlines the complete implementation of Option C: Full drag-and-drop with context menu fallback for the Budget Folders feature.

## Implementation Status

### ✅ Completed
1. **State Management**
   - `draggedItem: BudgetItem?` - Currently dragged item
   - `dropTargetId: String?` - Current drop target folder
   - `isDragging: Bool` - Drag operation in progress

2. **Color Coding**
   - 8 distinct folder colors
   - Deterministic color assignment
   - Visual indicators (dot, icon, badge)

3. **Basic Folder Operations**
   - Create, rename, delete folders
   - Expand/collapse functionality
   - Folder totals calculation

### 🚧 To Implement

#### Phase 1: Drag-and-Drop Core (High Priority)
1. **Add `.onDrag` modifier to items and folders**
   ```swift
   .onDrag {
       self.draggedItem = item
       self.isDragging = true
       return NSItemProvider(object: item.id as NSString)
   }
   ```

2. **Add `.onDrop` modifier to folders**
   ```swift
   .onDrop(of: [.text], delegate: FolderDropDelegate(...))
   ```

3. **Implement FolderDropDelegate**
   - `validateDrop()` - Check if drop is valid
   - `dropEntered()` - Set drop target, show visual feedback
   - `dropExited()` - Clear drop target
   - `performDrop()` - Execute the move operation

4. **Visual Feedback During Drag**
   - Reduce opacity of dragged item to 0.5
   - Highlight valid drop targets with green border
   - Show red border for invalid drop targets
   - Add pulsing animation on hover

5. **Drop Validation**
   - Prevent moving item to itself
   - Prevent circular references (folder into its descendant)
   - Enforce 3-level depth limit
   - Check if target is a folder

#### Phase 2: Context Menu System (High Priority)
1. **Add "Move to Folder" menu item**
   ```swift
   Menu {
       Button("Rename") { ... }
       
       Menu("Move to Folder") {
           Button("Root Level") {
               onMoveToFolder(nil)
           }
           ForEach(availableFolders) { folder in
               Button(folder.itemName) {
                   onMoveToFolder(folder.id)
               }
           }
       }
       
       Button("Delete", role: .destructive) { ... }
   }
   ```

2. **Filter Available Folders**
   - Exclude current folder
   - Exclude descendants (prevent circular refs)
   - Exclude folders at max depth
   - Show folder hierarchy with indentation

3. **Add Keyboard Shortcuts**
   - Cmd+M: Show move dialog
   - Cmd+X: Cut item
   - Cmd+V: Paste into folder
   - ESC: Cancel drag operation

#### Phase 3: Enhanced Visual Feedback (Medium Priority)
1. **Drop Target Highlighting**
   ```swift
   .background(
       isDragTarget ? 
           Color.green.opacity(0.2) : 
           Color(NSColor.controlBackgroundColor).opacity(0.5)
   )
   .overlay(
       isDragTarget ?
           RoundedRectangle(cornerRadius: 8)
               .stroke(Color.green, lineWidth: 2) :
           nil
   )
   ```

2. **Drag Preview**
   - Custom drag preview showing item name
   - Folder icon for folders
   - Item count badge for folders

3. **Drop Position Indicator**
   - Show line above/below for reordering
   - Show highlight inside for moving into folder
   - Calculate position based on mouse location

4. **Animation**
   - Smooth transition when item moves
   - Pulsing effect on drop target
   - Bounce animation on successful drop

#### Phase 4: Error Handling & Edge Cases (Medium Priority)
1. **Validation Errors**
   - Show alert for invalid moves
   - Explain why move failed
   - Suggest alternative actions

2. **Network Failures**
   - Optimistic updates with rollback
   - Show loading indicator
   - Retry mechanism
   - Error notifications

3. **Concurrent Modifications**
   - Handle item deleted during drag
   - Handle folder deleted during drag
   - Refresh data after drop

4. **Cancel Operations**
   - ESC key cancels drag
   - Clicking outside cancels drag
   - Reset drag state properly

#### Phase 5: Accessibility (High Priority)
1. **Keyboard Navigation**
   - Tab through items
   - Space to select
   - Cmd+M to show move menu
   - Arrow keys to navigate folders

2. **Screen Reader Support**
   - Announce drag start
   - Announce drop target
   - Announce successful move
   - Describe folder hierarchy

3. **Alternative Methods**
   - Context menu always available
   - Keyboard shortcuts
   - Cut/paste operations
   - Move dialog with folder picker

#### Phase 6: Performance Optimization (Low Priority)
1. **Debounce/Throttle**
   - Throttle hover events (100ms)
   - Debounce validation checks (50ms)
   - Cache validation results

2. **Minimize Re-renders**
   - Use `@State` carefully
   - Avoid unnecessary view updates
   - Optimize hierarchy calculations

3. **Large Hierarchies**
   - Virtualize long lists
   - Lazy load folder contents
   - Cache folder totals

## Implementation Order

### Week 1: Core Functionality
1. Day 1-2: Implement drag-and-drop modifiers
2. Day 3: Implement FolderDropDelegate with validation
3. Day 4: Add basic visual feedback (opacity, borders)
4. Day 5: Testing and bug fixes

### Week 2: Context Menu & Polish
1. Day 1-2: Implement context menu system
2. Day 3: Add keyboard shortcuts
3. Day 4: Enhanced visual feedback (animations)
4. Day 5: Accessibility improvements

### Week 3: Error Handling & Optimization
1. Day 1-2: Error handling and edge cases
2. Day 3: Performance optimization
3. Day 4-5: Comprehensive testing and documentation

## Testing Checklist

### Drag-and-Drop Tests
- [ ] Drag item to folder
- [ ] Drag folder to folder
- [ ] Drag item to root
- [ ] Prevent drag to self
- [ ] Prevent circular reference
- [ ] Enforce depth limit
- [ ] Cancel drag with ESC
- [ ] Visual feedback appears
- [ ] Drop target highlights correctly
- [ ] Invalid targets show red

### Context Menu Tests
- [ ] Move to folder via menu
- [ ] Move to root via menu
- [ ] Available folders filtered correctly
- [ ] Keyboard shortcuts work
- [ ] Menu shows folder hierarchy
- [ ] Disabled items are grayed out

### Edge Case Tests
- [ ] Drag while item is being edited
- [ ] Drop on deleted folder
- [ ] Network failure during move
- [ ] Concurrent modifications
- [ ] Very deep hierarchies (>10 levels)
- [ ] Many items (>1000)
- [ ] Rapid drag-and-drop operations

### Accessibility Tests
- [ ] VoiceOver announces drag start
- [ ] VoiceOver announces drop target
- [ ] VoiceOver announces successful move
- [ ] Keyboard navigation works
- [ ] Focus management correct
- [ ] Alternative methods available

## Success Criteria

### Functional
- ✅ Users can drag items to folders
- ✅ Users can use context menu to move items
- ✅ Visual feedback is clear and immediate
- ✅ Invalid moves are prevented
- ✅ Errors are handled gracefully

### Performance
- ✅ Drag operations feel smooth (<16ms frame time)
- ✅ No lag with 100+ items
- ✅ Validation is instant
- ✅ Animations are smooth

### Accessibility
- ✅ Fully keyboard accessible
- ✅ Screen reader compatible
- ✅ Alternative methods available
- ✅ Clear feedback for all operations

### Robustness
- ✅ Handles network failures
- ✅ Handles concurrent modifications
- ✅ Prevents data corruption
- ✅ Recovers from errors gracefully

## Code Structure

```
BudgetItemsTableView.swift
├── State Management
│   ├── draggedItem
│   ├── dropTargetId
│   └── isDragging
├── Drag-and-Drop Handlers
│   ├── handleDrop()
│   ├── handleMoveToFolder()
│   └── canMove()
├── Visual Feedback
│   ├── Opacity changes
│   ├── Border highlights
│   └── Animations
└── Context Menu
    ├── Move to Folder submenu
    ├── Keyboard shortcuts
    └── Folder hierarchy display

FolderDropDelegate.swift
├── validateDrop()
├── dropEntered()
├── dropExited()
└── performDrop()

FolderRowView.swift
├── Drag source
├── Drop target
├── Context menu
└── Visual feedback

BudgetItemRowView.swift
├── Drag source
├── Context menu
└── Visual feedback
```

## Next Steps

1. **Immediate**: Implement drag-and-drop core (Phase 1)
2. **This Week**: Add context menu system (Phase 2)
3. **Next Week**: Enhanced visual feedback and accessibility (Phases 3 & 5)
4. **Following Week**: Error handling and optimization (Phases 4 & 6)

## Notes

- Drag-and-drop provides quick, intuitive moves
- Context menu provides precise control and accessibility
- Both methods use the same validation logic
- Visual feedback is consistent across both methods
- Error handling is robust and user-friendly
