//
//  GuestImportView.swift
//  I Do Blueprint
//
//  Import guests from guest list into seating chart
//

import SwiftUI

struct GuestImportView: View {
    @Binding var isPresented: Bool
    let availableGuests: [SeatingGuest]
    let onImport: ([SeatingGuest]) -> Void
    
    @State private var selectedGuests: Set<UUID> = []
    @State private var searchText = ""
    @State private var filterByGroup: String?
    @State private var filterByRelationship: GuestRelationship?
    
    private var filteredGuests: [SeatingGuest] {
        availableGuests.filter { guest in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                guest.email.localizedCaseInsensitiveContains(searchText)
            
            // Group filter
            let matchesGroup = filterByGroup == nil || guest.group == filterByGroup
            
            // Relationship filter
            let matchesRelationship = filterByRelationship == nil || guest.relationship == filterByRelationship
            
            return matchesSearch && matchesGroup && matchesRelationship
        }
    }
    
    private var availableGroups: [String] {
        Array(Set(availableGuests.compactMap(\.group))).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Search and filters
            searchAndFiltersSection
            
            Divider()
            
            // Guest list
            guestListSection
            
            Divider()
            
            // Footer with actions
            footerSection
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Import Guests")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select guests to add to your seating chart")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Search and Filters
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search guests by name or email...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            // Filters
            HStack(spacing: 12) {
                // Group filter
                Menu {
                    Button("All Groups") {
                        filterByGroup = nil
                    }
                    
                    Divider()
                    
                    ForEach(availableGroups, id: \.self) { group in
                        Button(group) {
                            filterByGroup = group
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3")
                            .font(.system(size: 12))
                        Text(filterByGroup ?? "All Groups")
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(filterByGroup != nil ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(filterByGroup != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Relationship filter
                Menu {
                    Button("All Relationships") {
                        filterByRelationship = nil
                    }
                    
                    Divider()
                    
                    ForEach(GuestRelationship.allCases, id: \.self) { relationship in
                        Button(relationship.displayName) {
                            filterByRelationship = relationship
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                        Text(filterByRelationship?.displayName ?? "All Relationships")
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(filterByRelationship != nil ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(filterByRelationship != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Clear filters
                if filterByGroup != nil || filterByRelationship != nil {
                    Button("Clear Filters") {
                        filterByGroup = nil
                        filterByRelationship = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Guest List
    
    private var guestListSection: some View {
        VStack(spacing: 0) {
            // Selection controls
            HStack {
                Text("\(filteredGuests.count) guests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(selectedGuests.count == filteredGuests.count ? "Deselect All" : "Select All") {
                    if selectedGuests.count == filteredGuests.count {
                        selectedGuests.removeAll()
                    } else {
                        selectedGuests = Set(filteredGuests.map(\.id))
                    }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // Guest list
            ScrollView {
                LazyVStack(spacing: 8) {
                    if filteredGuests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No guests found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Try adjusting your search or filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(filteredGuests) { guest in
                            GuestImportRow(
                                guest: guest,
                                isSelected: selectedGuests.contains(guest.id),
                                onToggle: {
                                    if selectedGuests.contains(guest.id) {
                                        selectedGuests.remove(guest.id)
                                    } else {
                                        selectedGuests.insert(guest.id)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            Text("\(selectedGuests.count) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.bordered)
            
            Button("Import \(selectedGuests.count) Guest\(selectedGuests.count == 1 ? "" : "s")") {
                let guestsToImport = availableGuests.filter { selectedGuests.contains($0.id) }
                onImport(guestsToImport)
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedGuests.isEmpty)
        }
        .padding()
    }
}

// MARK: - Guest Import Row

struct GuestImportRow: View {
    let guest: SeatingGuest
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                // Guest avatar
                ZStack {
                    Circle()
                        .fill(guest.relationship.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text(guest.initials)
                        .font(.system(size: 12, weight: .semibold))
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
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                        }
                        
                        if guest.plusOne != nil {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(guest.relationship.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(guest.relationship.color.opacity(0.2))
                            .foregroundColor(guest.relationship.color)
                            .cornerRadius(4)
                        
                        if let group = guest.group {
                            Text(group)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GuestImportView(
        isPresented: .constant(true),
        availableGuests: [
            SeatingGuest(firstName: "John", lastName: "Smith", relationship: .friend, group: "College Friends"),
            SeatingGuest(firstName: "Sarah", lastName: "Johnson", relationship: .family, group: "Immediate Family", isVIP: true),
            SeatingGuest(firstName: "Michael", lastName: "Brown", relationship: .groomSide, group: "Groom's Family"),
            SeatingGuest(firstName: "Emily", lastName: "Davis", relationship: .brideSide, group: "Bride's Friends"),
            SeatingGuest(firstName: "Robert", lastName: "Wilson", relationship: .coworker, group: "Work Friends")
        ],
        onImport: { guests in
            print("Importing \(guests.count) guests")
        }
    )
}
