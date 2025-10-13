import SwiftUI

struct AddVendorView: View {
    let onSave: (Vendor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var vendorName = ""
    @State private var vendorType = ""
    @State private var budgetCategoryName = ""
    @State private var contactName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var website = ""
    @State private var address = ""
    @State private var quotedAmount = ""
    @State private var notes = ""
    @State private var businessDescription = ""
    @State private var selectedVendorType = VendorType.other

    enum VendorType: String, CaseIterable {
        case venue = "Venue"
        case caterer = "Caterer"
        case photographer = "Photographer"
        case florist = "Florist"
        case musician = "Musician"
        case transportation = "Transportation"
        case baker = "Baker"
        case decorator = "Decorator"
        case officiant = "Officiant"
        case other = "Other"

        var budgetCategory: String {
            switch self {
            case .venue: "Venue"
            case .caterer: "Catering"
            case .photographer: "Photography"
            case .florist: "Flowers & Decorations"
            case .musician: "Entertainment"
            case .transportation: "Transportation"
            case .baker: "Cake & Desserts"
            case .decorator: "Decorations"
            case .officiant: "Ceremony"
            case .other: "Other"
            }
        }
    }

    private var isFormValid: Bool {
        !vendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Vendor Name", text: $vendorName)

                    Picker("Vendor Type", selection: $selectedVendorType) {
                        ForEach(VendorType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: selectedVendorType) { _, newValue in
                        vendorType = newValue.rawValue
                        budgetCategoryName = newValue.budgetCategory
                    }

                    TextField("Contact Person", text: $contactName)
                }

                Section("Contact Information") {
                    TextField("Phone Number", text: $phoneNumber)

                    TextField("Email", text: $email)

                    TextField("Website", text: $website)

                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2 ... 4)
                }

                Section("Financial") {
                    TextField("Quoted Amount", text: $quotedAmount)
                        .overlay(alignment: .leading) {
                            Text("$")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        }
                        .padding(.leading, 16)
                }

                Section("Additional Details") {
                    TextField("Business Description", text: $businessDescription, axis: .vertical)
                        .lineLimit(3 ... 6)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Add Vendor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveVendor()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            // Set default values
            vendorType = selectedVendorType.rawValue
            budgetCategoryName = selectedVendorType.budgetCategory
        }
    }

    private func saveVendor() {
        let newVendor = Vendor(
            id: 0, // Database will auto-generate
            createdAt: Date(),
            updatedAt: nil,
            vendorName: vendorName.trimmingCharacters(in: .whitespacesAndNewlines),
            vendorType: vendorType.isEmpty ? nil : vendorType,
            vendorCategoryId: budgetCategoryName.isEmpty ? nil : budgetCategoryName,
            contactName: contactName.isEmpty ? nil : contactName,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            email: email.isEmpty ? nil : email,
            website: website.isEmpty ? nil : website,
            notes: notes.isEmpty ? nil : notes,
            quotedAmount: Double(quotedAmount),
            imageUrl: nil,
            isBooked: false,
            budgetCategoryId: nil, // Would need to be looked up from budget categories
            coupleId: UUID(), // This should come from current user/couple context
            isArchived: false,
            archivedAt: nil,
            includeInExport: false) // New vendors default to not included in export

        onSave(newVendor)
        dismiss()
    }
}

#Preview {
    AddVendorView { vendor in
        print("Saved vendor: \(vendor.vendorName)")
    }
}
