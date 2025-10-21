//
//  EditVendorSheetV2.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/8/25.
//  Modal for editing vendor details from vendor list
//

import SwiftUI

struct EditVendorSheetV2: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vendorStore: VendorStoreV2

    let vendor: Vendor
    let onSave: (Vendor) -> Void

    @State private var vendorName: String
    @State private var vendorType: String
    @State private var contactName: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var website: String
    @State private var quotedAmount: String
    @State private var isBooked: Bool
    @State private var dateBooked: Date?
    @State private var notes: String
    @State private var isSaving = false

    init(vendor: Vendor, vendorStore: VendorStoreV2, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        self.onSave = onSave
        _vendorName = State(initialValue: vendor.vendorName)
        _vendorType = State(initialValue: vendor.vendorType ?? "")
        _contactName = State(initialValue: vendor.contactName ?? "")
        _email = State(initialValue: vendor.email ?? "")
        _phoneNumber = State(initialValue: vendor.phoneNumber ?? "")
        _website = State(initialValue: vendor.website ?? "")
        _quotedAmount = State(initialValue: vendor.quotedAmount.map { String(format: "%.0f", $0) } ?? "")
        _isBooked = State(initialValue: vendor.isBooked ?? false)
        _dateBooked = State(initialValue: vendor.dateBooked)
        _notes = State(initialValue: vendor.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Vendor")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(vendor.vendorName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Form Content
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Information
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Basic Information", icon: "info.circle.fill")

                        VStack(spacing: 16) {
                            FormField(label: "Business Name", required: true) {
                                TextField("Enter business name", text: $vendorName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FormField(label: "Service Type") {
                                TextField("e.g., Photography, Catering", text: $vendorType)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }

                    Divider()

                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Contact Information", icon: "envelope.circle.fill")

                        VStack(spacing: 16) {
                            FormField(label: "Contact Person") {
                                TextField("Contact name", text: $contactName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FormField(label: "Email") {
                                TextField("contact@example.com", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                            }

                            FormField(label: "Phone") {
                                TextField("(555) 123-4567", text: $phoneNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.telephoneNumber)
                            }

                            FormField(label: "Website") {
                                TextField("https://example.com", text: $website)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.URL)
                            }
                        }
                    }

                    Divider()

                    // Business Details
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Business Details", icon: "building.2.circle.fill")

                        VStack(spacing: 16) {
                            FormField(label: "Status") {
                                Toggle("Booked", isOn: $isBooked)
                                    .toggleStyle(.switch)
                                    .onChange(of: isBooked) { oldValue, newValue in
                                        // Auto-set date when marking as booked
                                        if newValue && dateBooked == nil {
                                            dateBooked = Date()
                                        }
                                    }
                            }

                            if isBooked {
                                FormField(label: "Booked Date") {
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { dateBooked ?? Date() },
                                            set: { dateBooked = $0 }
                                        ),
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                                }
                            }

                            FormField(label: "Quoted Amount") {
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    TextField("0", text: $quotedAmount)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Notes", icon: "note.text")

                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    Task {
                        await saveVendor()
                    }
                } label: {
                    if isSaving {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving...")
                        }
                    } else {
                        Text("Save Changes")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || vendorName.isEmpty)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .frame(width: 600, height: 700)
    }

    private func saveVendor() async {
        isSaving = true
        defer { isSaving = false }

        var updatedVendor = vendor
        updatedVendor.vendorName = vendorName
        updatedVendor.vendorType = vendorType.isEmpty ? nil : vendorType
        updatedVendor.contactName = contactName.isEmpty ? nil : contactName
        updatedVendor.email = email.isEmpty ? nil : email
        updatedVendor.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        updatedVendor.website = website.isEmpty ? nil : website
        updatedVendor.quotedAmount = Double(quotedAmount)
        updatedVendor.isBooked = isBooked
        updatedVendor.dateBooked = isBooked ? dateBooked : nil
        updatedVendor.notes = notes.isEmpty ? nil : notes
        updatedVendor.updatedAt = Date()

        await vendorStore.updateVendor(updatedVendor)
        onSave(updatedVendor)
        dismiss()
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.Vendor.contacted)
            Text(title)
                .font(.headline)
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            content
        }
    }
}

#Preview {
    EditVendorSheetV2(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Sample Vendor",
            vendorType: "Photography",
            vendorCategoryId: nil,
            contactName: "John Doe",
            phoneNumber: "(555) 123-4567",
            email: "john@example.com",
            website: "https://example.com",
            notes: "Sample notes",
            quotedAmount: 3000,
            imageUrl: nil,
            isBooked: false,
            dateBooked: nil,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        vendorStore: VendorStoreV2(),
        onSave: { _ in }
    )
}
