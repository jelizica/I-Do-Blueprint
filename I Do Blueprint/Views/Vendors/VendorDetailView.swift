import AppKit
import SwiftUI

extension ContractStatus {
    var color: Color {
        switch self {
        case .draft: .gray
        case .pending: .orange
        case .signed: .green
        case .expired: .red
        case .none: .gray
        }
    }
}

struct VendorDetailView: View {
    let vendor: Vendor
    let onSave: (Vendor) -> Void

    @State private var isEditing = false
    @State private var editedVendor: Vendor
    @State private var vendorDetails: VendorDetails
    @State private var isLoadingDetails = true
    @EnvironmentObject var vendorStore: VendorStoreV2

    init(vendor: Vendor, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.onSave = onSave
        _editedVendor = State(initialValue: vendor)
        _vendorDetails = State(initialValue: VendorDetails(vendor: vendor))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with vendor image and basic info
                VendorHeaderView(vendor: vendor)

                // Status indicators
                VendorStatusView(vendor: vendor, vendorDetails: vendorDetails)

                // Tabs for different sections
                VendorTabsView(vendor: vendor, vendorDetails: vendorDetails, editedVendor: $editedVendor, isEditing: isEditing)
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle(vendor.vendorName)
        .task {
            await loadVendorDetails()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            editedVendor = vendor
                            isEditing = false
                        }
                        .buttonStyle(.bordered)

                        Button("Save") {
                            onSave(editedVendor)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func loadVendorDetails() async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        // Fetch extended data in parallel
        async let reviewStats = try? await vendorStore.repository.fetchVendorReviewStats(vendorId: vendor.id)
        async let paymentSummary = try? await vendorStore.repository.fetchVendorPaymentSummary(vendorId: vendor.id)
        async let contractInfo = try? await vendorStore.repository.fetchVendorContractSummary(vendorId: vendor.id)

        vendorDetails.reviewStats = await reviewStats
        vendorDetails.paymentSummary = await paymentSummary
        vendorDetails.contractInfo = await contractInfo
    }
}

struct VendorHeaderView: View {
    let vendor: Vendor

    var body: some View {
        VStack(spacing: 20) {
            // Vendor image
            AsyncImage(url: URL(string: vendor.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5)))
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2))

            VStack(spacing: 12) {
                Text(vendor.vendorName)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .multilineTextAlignment(.center)

                if let category = vendor.budgetCategoryName {
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.12)))
                        .foregroundColor(.blue)
                }

                if let contact = vendor.contactName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.secondary)
                        Text(contact)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))
    }
}

struct VendorStatusView: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails

    var body: some View {
        HStack(spacing: 12) {
            // Booking status
            StatusIndicator(
                title: "Status",
                value: vendor.isArchived ? "Archived" : ((vendor.isBooked == true) ? "Booked" : "Available"),
                color: vendor.isArchived ? .gray : ((vendor.isBooked == true) ? .green : .orange),
                icon: vendor
                    .isArchived ? "archivebox.fill" : ((vendor.isBooked == true) ? "checkmark.circle.fill" : "circle"))

            // Contract status
            if vendorDetails.contractStatus != .none {
                StatusIndicator(
                    title: "Contract",
                    value: vendorDetails.contractStatus.displayName,
                    color: vendorDetails.contractStatus.color,
                    icon: "doc.text.fill")
            }

            // Rating
            if let rating = vendorDetails.avgRating, rating > 0 {
                StatusIndicator(
                    title: "Rating",
                    value: String(format: "%.1f", rating),
                    color: .yellow,
                    icon: "star.fill")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))
    }
}

struct StatusIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VendorTabsView: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails
    @Binding var editedVendor: Vendor
    let isEditing: Bool
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 20) {
            // Tab picker
            Picker("Sections", selection: $selectedTab) {
                Text("Details").tag(0)
                Text("Contact").tag(1)
                Text("Financial").tag(2)
                Text("Contract").tag(3)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Tab content wrapped in card
            Group {
                switch selectedTab {
                case 0:
                    VendorDetailsTab(vendor: vendor, editedVendor: $editedVendor, isEditing: isEditing)
                case 1:
                    VendorContactTab(vendor: vendor, editedVendor: $editedVendor, isEditing: isEditing)
                case 2:
                    VendorFinancialTab(vendor: vendor, vendorDetails: vendorDetails, editedVendor: $editedVendor, isEditing: isEditing)
                case 3:
                    VendorContractTab(vendor: vendor, vendorDetails: vendorDetails, editedVendor: $editedVendor, isEditing: isEditing)
                default:
                    EmptyView()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }
}

struct VendorDetailsTab: View {
    let vendor: Vendor
    @Binding var editedVendor: Vendor
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            DetailRow(
                title: "Vendor Type",
                value: vendor.vendorType ?? "Not specified",
                isEditing: isEditing,
                editValue: Binding(
                    get: { editedVendor.vendorType ?? "" },
                    set: { editedVendor.vendorType = $0.isEmpty ? nil : $0 }))

            if let address = vendor.address {
                DetailRow(
                    title: "Address",
                    value: address,
                    isEditing: isEditing,
                    editValue: Binding(
                        get: { editedVendor.address ?? "" },
                        set: { _ in
                            // Note: address is a computed property that returns nil
                            // In a real implementation, this would update the appropriate database field
                        }))
            }

            if let description = vendor.businessDescription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Business Description")
                        .font(.headline)
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let notes = vendor.notes {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct VendorContactTab: View {
    let vendor: Vendor
    @Binding var editedVendor: Vendor
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let phone = vendor.phoneNumber {
                ContactRow(
                    icon: "phone.fill",
                    title: "Phone",
                    value: phone,
                    action: { URL(string: "tel:\(phone)") })
            }

            if let email = vendor.email {
                ContactRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: email,
                    action: { URL(string: "mailto:\(email)") })
            }

            if let website = vendor.website {
                ContactRow(
                    icon: "globe",
                    title: "Website",
                    value: website,
                    action: { URL(string: website) })
            }
        }
    }
}

struct VendorFinancialTab: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails
    @Binding var editedVendor: Vendor
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let amount = vendor.quotedAmount {
                FinancialRow(
                    title: "Quoted Amount",
                    amount: amount,
                    color: .blue)
            }

            if let paymentDate = vendorDetails.finalPaymentDue {
                DetailRow(
                    title: "Final Payment Due",
                    value: formatDate(paymentDate),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let nextPayment = vendorDetails.nextPaymentDue {
                DetailRow(
                    title: "Next Payment Due",
                    value: formatDate(nextPayment),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let paymentSummary = vendorDetails.paymentSummary {
                VStack(spacing: 12) {
                    FinancialRow(
                        title: "Total Amount",
                        amount: paymentSummary.totalAmount,
                        color: .blue)

                    FinancialRow(
                        title: "Paid Amount",
                        amount: paymentSummary.paidAmount,
                        color: .green)

                    FinancialRow(
                        title: "Remaining Amount",
                        amount: paymentSummary.remainingAmount,
                        color: .orange)
                }
            }
        }
    }
}

struct VendorContractTab: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails
    @Binding var editedVendor: Vendor
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            if vendorDetails.contractStatus != .none {
                DetailRow(
                    title: "Contract Status",
                    value: vendorDetails.contractStatus.displayName,
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let signedDate = vendorDetails.contractSignedDate {
                DetailRow(
                    title: "Contract Signed",
                    value: formatDate(signedDate),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let expiryDate = vendorDetails.contractExpiryDate {
                DetailRow(
                    title: "Contract Expires",
                    value: formatDate(expiryDate),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let bookingDate = vendor.bookingDate {
                DetailRow(
                    title: "Booking Date",
                    value: formatDate(bookingDate),
                    isEditing: false,
                    editValue: .constant(""))
            }
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let value: String
    let isEditing: Bool
    @Binding var editValue: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)

            if isEditing {
                TextField(title, text: $editValue)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> URL?
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()

            if let url = action() {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.12)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.08 : 0.04), radius: isHovering ? 6 : 3, x: 0, y: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct FinancialRow: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(color)
                    .font(.system(size: 24))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1.5))
    }
}

// MARK: - Helper Functions

private func formatDate(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    if let date = formatter.date(from: dateString) {
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    return dateString
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

#Preview {
    VendorDetailView(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Elegant Flowers",
            vendorType: "Florist",
            vendorCategoryId: "flowers",
            contactName: "Sarah Johnson",
            phoneNumber: "(555) 123-4567",
            email: "sarah@elegantflowers.com",
            website: "https://elegantflowers.com",
            notes: "Specializes in wedding bouquets and centerpieces",
            quotedAmount: 2500.0,
            imageUrl: nil,
            isBooked: true,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true)) { _ in }
}
