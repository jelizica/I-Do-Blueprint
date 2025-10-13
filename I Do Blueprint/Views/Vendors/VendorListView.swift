import AppKit
import SwiftUI

struct VendorListView: View {
    @StateObject private var vendorStore = VendorStoreV2()
    @State private var searchText = ""
    @State private var selectedFilter: VendorFilterOption = .all
    @State private var selectedSort: VendorSortOption = .name
    @State private var sortAscending = true
    @State private var showingAddVendor = false
    @State private var selectedVendor: Vendor?

    var filteredAndSortedVendors: [Vendor] {
        let filtered = vendorStore.vendors.filter { vendor in
            // Apply search filter
            let matchesSearch = searchText.isEmpty ||
                vendor.vendorName.localizedCaseInsensitiveContains(searchText) ||
                vendor.vendorType?.localizedCaseInsensitiveContains(searchText) == true ||
                vendor.budgetCategoryName?.localizedCaseInsensitiveContains(searchText) == true

            // Apply status filter
            let matchesFilter: Bool = switch selectedFilter {
            case .all:
                true
            case .available:
                !(vendor.isBooked ?? false) && !vendor.isArchived
            case .booked:
                (vendor.isBooked ?? false) && !vendor.isArchived
            case .archived:
                vendor.isArchived
            }

            return matchesSearch && matchesFilter
        }

        // Apply sorting
        return filtered.sorted { (vendor1: Vendor, vendor2: Vendor) -> Bool in
            let comparison: Bool
            switch selectedSort {
            case .name:
                comparison = vendor1.vendorName < vendor2.vendorName
            case .category:
                comparison = (vendor1.budgetCategoryName ?? "") < (vendor2.budgetCategoryName ?? "")
            case .cost:
                comparison = (vendor1.quotedAmount ?? 0) < (vendor2.quotedAmount ?? 0)
            case .rating:
                // Rating sort not available in list view - would need async fetch
                comparison = vendor1.vendorName < vendor2.vendorName
            case .bookingDate:
                comparison = (vendor1.dateBooked ?? .distantPast) < (vendor2.dateBooked ?? .distantPast)
            }
            return sortAscending ? comparison : !comparison
        }
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left panel - Vendor list
                VStack(spacing: 0) {
                    // Header with stats
                    VendorStatsHeaderView(stats: vendorStore.stats)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))

                    // Search and filters
                    VStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search vendors...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Filter and sort controls
                        HStack {
                            // Filter picker
                            Picker("Filter", selection: $selectedFilter) {
                                ForEach(VendorFilterOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Spacer()

                            // Sort controls
                            Menu {
                                ForEach(VendorSortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        if selectedSort == option {
                                            sortAscending.toggle()
                                        } else {
                                            selectedSort = option
                                            sortAscending = true
                                        }
                                    }) {
                                        HStack {
                                            Text(option.displayName)
                                            if selectedSort == option {
                                                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Sort")
                                    Image(systemName: "arrow.up.arrow.down")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .background(Color(NSColor.controlBackgroundColor))

                    Divider()

                    // Vendor list
                    if filteredAndSortedVendors.isEmpty {
                        ContentUnavailableView(
                            "No Vendors Found",
                            systemImage: "person.3.fill",
                            description: Text(searchText
                                .isEmpty ? "Add your first vendor to get started" :
                                "Try adjusting your search or filters"))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredAndSortedVendors) { vendor in
                                    Button(action: {
                                        selectedVendor = vendor
                                    }) {
                                        VendorRowView(vendor: vendor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(12)
                        }
                        .background(Color(NSColor.windowBackgroundColor))
                    }
                }
                .frame(width: 420)

                Divider()

                // Right panel - Detail view
                if let vendor = selectedVendor {
                    VendorDetailView(vendor: vendor) { updatedVendor in
                        Task {
                            await vendorStore.updateVendor(updatedVendor)
                        }
                    }
                    .id(vendor.id)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a vendor to view details")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
            .navigationTitle("Vendors")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddVendor = true
                    }) {
                        Label("Add Vendor", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Button(action: {
                        Task {
                            await vendorStore.refreshVendors()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddVendor) {
                AddVendorView { newVendor in
                    Task {
                        await vendorStore.addVendor(newVendor)
                    }
                }
                #if os(macOS)
                .frame(minWidth: 500, maxWidth: 600, minHeight: 500, maxHeight: 650)
                #endif
            }
            .task {
                await vendorStore.loadVendors()
            }
        }
    }
}

// MARK: - Supporting Views

struct VendorStatsHeaderView: View {
    let stats: VendorStats

    var body: some View {
        HStack(spacing: 12) {
            VendorStatCard(title: "Total", value: "\(stats.total)", color: .blue, icon: "building.2.fill")
            VendorStatCard(title: "Booked", value: "\(stats.booked)", color: .green, icon: "checkmark.circle.fill")
            VendorStatCard(title: "Available", value: "\(stats.available)", color: .orange, icon: "circle")
            VendorStatCard(title: "Archived", value: "\(stats.archived)", color: .gray, icon: "archivebox.fill")
        }
    }
}

struct VendorRowView: View {
    let vendor: Vendor
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            // Vendor image or placeholder
            AsyncImage(url: URL(string: vendor.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.title2))
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(vendor.vendorName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Spacer()

                    if let amount = vendor.quotedAmount {
                        Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }

                if let category = vendor.budgetCategoryName {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    // Status badges
                    if vendor.isArchived {
                        StatusBadge(text: "Archived", color: .gray)
                    } else if vendor.isBooked == true {
                        StatusBadge(text: "Booked", color: .green)
                    } else {
                        StatusBadge(text: "Available", color: .orange)
                    }

                    // Note: Contract and rating info removed from list view for performance
                    // These are displayed in detail view after async fetch

                    Spacer()
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(isHovering ? 1.0 : 0.5))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 4,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct VendorStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.1 : 0.06),
                    radius: isHovering ? 6 : 3,
                    x: 0,
                    y: isHovering ? 3 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1))
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Extensions

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}

#Preview {
    VendorListView()
}
