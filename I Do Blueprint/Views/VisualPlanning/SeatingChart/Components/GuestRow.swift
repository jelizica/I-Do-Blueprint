//
//  GuestRow.swift
//  I Do Blueprint
//
//  Display guest in seating chart context with drag-and-drop support
//

import SwiftUI

struct GuestRow: View {
    let guest: SeatingGuest
    let assignedTable: Table?
    let onAssign: () -> Void
    let onUnassign: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Guest avatar/initials
            ZStack {
                Circle()
                    .fill(guest.relationship.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(guest.initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(guest.relationship.color)
            }
            
            // Guest info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(guest.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if guest.isVIP {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                    
                    if guest.plusOne != nil {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 8) {
                    // Relationship badge
                    Text(guest.relationship.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(guest.relationship.color.opacity(0.2))
                        .foregroundColor(guest.relationship.color)
                        .cornerRadius(4)
                    
                    // Group badge
                    if let group = guest.group {
                        Text(group)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Dietary restrictions icon
                    if !guest.dietaryRestrictions.isEmpty {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                            .help(guest.dietaryRestrictions)
                    }
                    
                    // Accessibility icon
                    if let accessibility = guest.accessibility,
                       accessibility.wheelchairAccessible || accessibility.mobilityLimited {
                        Image(systemName: "figure.roll")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .help("Accessibility needs")
                    }
                }
            }
            
            Spacer()
            
            // Assignment status and actions
            if let table = assignedTable {
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Table \(table.tableNumber)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        if let tableName = table.tableName {
                            Text(tableName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: onUnassign) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Unassign from table")
                }
            } else {
                Button(action: onAssign) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Assign")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Assign to table")
            }
            
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .help("Drag to assign to table")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(assignedTable != nil ? Color.green.opacity(0.05) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(assignedTable != nil ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        // Unassigned guest
        GuestRow(
            guest: SeatingGuest(
                firstName: "John",
                lastName: "Smith",
                email: "john@example.com",
                relationship: .friend,
                group: "College Friends",
                isVIP: false
            ),
            assignedTable: nil,
            onAssign: { print("Assign tapped") },
            onUnassign: { print("Unassign tapped") }
        )
        
        // Assigned VIP guest with plus-one
        GuestRow(
            guest: {
                var guest = SeatingGuest(
                    firstName: "Sarah",
                    lastName: "Johnson",
                    email: "sarah@example.com",
                    relationship: .family,
                    group: "Immediate Family",
                    isVIP: true
                )
                guest.plusOne = UUID()
                guest.dietaryRestrictions = "Vegetarian"
                return guest
            }(),
            assignedTable: Table(tableNumber: 5, shape: .round, capacity: 8),
            onAssign: { print("Assign tapped") },
            onUnassign: { print("Unassign tapped") }
        )
        
        // Guest with accessibility needs
        GuestRow(
            guest: {
                var guest = SeatingGuest(
                    firstName: "Robert",
                    lastName: "Williams",
                    email: "robert@example.com",
                    relationship: .groomSide,
                    group: "Groom's Family",
                    isVIP: false
                )
                guest.accessibility = AccessibilityNeeds()
                guest.accessibility?.wheelchairAccessible = true
                return guest
            }(),
            assignedTable: Table(tableNumber: 2, shape: .rectangular, capacity: 10),
            onAssign: { print("Assign tapped") },
            onUnassign: { print("Unassign tapped") }
        )
    }
    .padding()
    .frame(width: 450)
}
