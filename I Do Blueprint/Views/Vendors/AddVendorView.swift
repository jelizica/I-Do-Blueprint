import SwiftUI
import Dependencies
import PhoneNumberKit

struct AddVendorView: View {
    private let logger = AppLogger.ui
    let onSave: (Vendor) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.vendorRepository) var repository

    @State private var vendorName = ""
    @State private var vendorType = ""
    @State private var budgetCategoryName = ""
    @State private var contactName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var website = ""
    @State private var streetAddress = ""
    @State private var streetAddress2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "US"
    @State private var quotedAmount = ""
    @State private var notes = ""
    @State private var businessDescription = ""
    @State private var selectedVendorType: VendorType?
    @State private var vendorTypes: [VendorType] = []
    @State private var isLoadingTypes = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !vendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Two-column layout for better space utilization
                    HStack(alignment: .top, spacing: 20) {
                        // Left Column
                        VStack(spacing: 16) {
                            // Basic Information
                            GroupBox(label: Text("Basic Information").font(.headline)) {
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Vendor Name *")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Enter vendor name", text: $vendorName)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Vendor Type")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if isLoadingTypes {
                                            HStack {
                                                ProgressView()
                                                    .scaleEffect(0.7)
                                                Text("Loading types...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, Spacing.xs)
                                        } else if vendorTypes.isEmpty {
                                            Text("No vendor types available")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.vertical, Spacing.xs)
                                        } else {
                                            Picker("", selection: $selectedVendorType) {
                                                Text("Select type...").tag(nil as VendorType?)
                                                ForEach(vendorTypes) { type in
                                                    Text(type.vendorType).tag(type as VendorType?)
                                                }
                                            }
                                            .labelsHidden()
                                            .onChange(of: selectedVendorType) { _, newValue in
                                                if let newValue = newValue {
                                                    vendorType = newValue.vendorType
                                                    budgetCategoryName = newValue.vendorType
                                                }
                                            }
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Contact Person")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Enter contact name", text: $contactName)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(.vertical, Spacing.sm)
                            }

                            // Contact Information
                            GroupBox(label: Text("Contact Information").font(.headline)) {
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Phone Number")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        PhoneNumberTextFieldWrapper(
                                            phoneNumber: $phoneNumber,
                                            defaultRegion: "US",
                                            placeholder: "(555) 123-4567"
                                        )
                                        .frame(height: 40)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Email")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("email@example.com", text: $email)
                                            .textContentType(.emailAddress)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Website")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("https://example.com", text: $website)
                                            .textContentType(.URL)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(.vertical, Spacing.sm)
                            }

                            // Financial
                            GroupBox(label: Text("Financial").font(.headline)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Quoted Amount")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Text("$")
                                            .foregroundColor(.secondary)
                                        TextField("0.00", text: $quotedAmount)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(.vertical, Spacing.sm)
                            }
                        }

                        // Right Column
                        VStack(spacing: 16) {
                            // Address
                            GroupBox(label: Text("Address").font(.headline)) {
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Street Address")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("123 Main St", text: $streetAddress)
                                            .textContentType(.streetAddressLine1)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Street Address 2 (Optional)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Apt, Suite, etc.", text: $streetAddress2)
                                            .textContentType(.streetAddressLine2)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("City")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("City", text: $city)
                                                .textContentType(.addressCity)
                                                .textFieldStyle(.roundedBorder)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("State")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("ST", text: $state)
                                                .textContentType(.addressState)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 60)
                                        }
                                    }

                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Postal Code")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("12345", text: $postalCode)
                                                .textContentType(.postalCode)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 100)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Country")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("US", text: $country)
                                                .textContentType(.countryName)
                                                .textFieldStyle(.roundedBorder)
                                        }
                                    }
                                }
                                .padding(.vertical, Spacing.sm)
                            }

                            // Additional Details
                            GroupBox(label: Text("Additional Details").font(.headline)) {
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Business Description")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextEditor(text: $businessDescription)
                                            .frame(height: 60)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextEditor(text: $notes)
                                            .frame(height: 60)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.vertical, Spacing.sm)
                            }
                        }
                    }
                    .padding()
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
                        Task {
                            await saveVendor()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isSaving)
                }
            }
        }
        .task {
            await loadVendorTypes()
        }
        .alert("Error Saving Vendor", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .overlay {
            if isSaving {
                ZStack {
                    SemanticColors.textPrimary.opacity(Opacity.light)
                        .ignoresSafeArea()

                    ProgressView("Saving vendor...")
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }

    private func saveVendor() async {
        // Validate required fields
        guard !vendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Vendor name is required"
            return
        }

        // Get current couple ID from session
        guard let coupleId = await MainActor.run(body: {
            SessionManager.shared.getTenantId()
        }) else {
            errorMessage = "No couple selected. Please select your wedding couple to continue."
            return
        }

        isSaving = true
        errorMessage = nil

        // Create vendor with proper field mapping
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
            quotedAmount: quotedAmount.isEmpty ? nil : Double(quotedAmount),
            imageUrl: nil,
            isBooked: false,
            dateBooked: nil,
            budgetCategoryId: nil, // Would need to be looked up from budget categories
            coupleId: coupleId,
            isArchived: false,
            archivedAt: nil,
            includeInExport: false,
            streetAddress: streetAddress.isEmpty ? nil : streetAddress,
            streetAddress2: streetAddress2.isEmpty ? nil : streetAddress2,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            postalCode: postalCode.isEmpty ? nil : postalCode,
            country: country.isEmpty ? nil : country,
            latitude: nil,
            longitude: nil
        )

        await onSave(newVendor)

        isSaving = false
        dismiss()
    }

    private func loadVendorTypes() async {
        isLoadingTypes = true
        do {
            vendorTypes = try await repository.fetchVendorTypes()
            // Set first type as default if available
            if let firstType = vendorTypes.first {
                selectedVendorType = firstType
                vendorType = firstType.vendorType
                budgetCategoryName = firstType.vendorType
            }
        } catch {
            errorMessage = "Failed to load vendor types: \(error.localizedDescription)"
            AppLogger.repository.error("Failed to load vendor types", error: error)
        }
        isLoadingTypes = false
    }
}

#Preview {
    AddVendorView { vendor in
        // TODO: Implement action - print("Saved vendor: \(vendor.vendorName)")
    }
}
