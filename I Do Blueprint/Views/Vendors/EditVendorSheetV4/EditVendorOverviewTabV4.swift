//
//  EditVendorOverviewTabV4.swift
//  I Do Blueprint
//
//  Overview tab for Edit Vendor Modal V4
//  Contains: Identity, Contact, Location, Social Media, Status & Settings sections
//

import SwiftUI

struct EditVendorOverviewTabV4: View {
    // MARK: - Bindings
    
    @Binding var vendorName: String
    @Binding var vendorType: String
    @Binding var priorityLevel: VendorPriority
    @Binding var contactEmail: String
    @Binding var phoneNumber: String
    @Binding var website: String
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var country: String
    @Binding var instagramHandle: String
    @Binding var isBooked: Bool
    @Binding var dateBooked: Date
    @Binding var includeInExport: Bool
    @Binding var isArchived: Bool
    @Binding var quickNote: String
    
    // MARK: - Constants
    
    private let vendorCategories = [
        "Hair & Makeup",
        "Photography",
        "Videography",
        "Venue",
        "Catering",
        "Florist",
        "DJ/Music",
        "Wedding Planner",
        "Officiant",
        "Transportation",
        "Rentals",
        "Stationery",
        "Cake/Desserts",
        "Other"
    ]
    
    private let countries = ["USA", "Canada", "UK", "Australia", "Other"]
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xxl) {
            // Left Column - Identity & Contact
            VStack(spacing: Spacing.xxl) {
                identitySection
                contactSection
            }
            .frame(maxWidth: .infinity)
            
            // Middle Column - Location & Social
            VStack(spacing: Spacing.xxl) {
                locationSection
                socialMediaSection
            }
            .frame(maxWidth: .infinity)
            
            // Right Column - Status & Settings
            VStack(spacing: Spacing.lg) {
                statusSettingsCard
                quickNoteCard
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Identity Section
    
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader(icon: "person.crop.rectangle", title: "Identity")
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Vendor Name
                formField(label: "Vendor Name") {
                    TextField("Enter vendor name", text: $vendorName)
                        .textFieldStyle(.plain)
                        .padding(Spacing.md)
                        .background(glassFieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .overlay(fieldBorder)
                }
                
                // Category
                formField(label: "Category") {
                    Menu {
                        ForEach(vendorCategories, id: \.self) { category in
                            Button(category) {
                                vendorType = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(vendorType.isEmpty ? "Select category" : vendorType)
                                .foregroundColor(vendorType.isEmpty ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                        .padding(Spacing.md)
                        .background(glassFieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .overlay(fieldBorder)
                    }
                    .buttonStyle(.plain)
                }
                
                // Priority Level
                formField(label: "Priority Level") {
                    HStack(spacing: Spacing.sm) {
                        ForEach(VendorPriority.allCases, id: \.self) { priority in
                            priorityButton(priority)
                        }
                    }
                }
            }
        }
    }
    
    private func priorityButton(_ priority: VendorPriority) -> some View {
        Button {
            priorityLevel = priority
        } label: {
            Text(priority.rawValue)
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(priorityLevel == priority ? priority.color : SemanticColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    priorityLevel == priority ? priority.backgroundColor : SemanticColors.backgroundPrimary
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(
                            priorityLevel == priority ? priority.color : SemanticColors.borderLight,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader(icon: "envelope", title: "Contact")
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Email
                formField(label: "Email Address") {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "envelope")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textTertiary)
                        TextField("hello@example.com", text: $contactEmail)
                            .textFieldStyle(.plain)
                    }
                    .padding(Spacing.md)
                    .background(glassFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .overlay(fieldBorder)
                }
                
                // Phone
                formField(label: "Phone Number") {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "phone")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textTertiary)
                        TextField("+1 (555) 123-4567", text: $phoneNumber)
                            .textFieldStyle(.plain)
                    }
                    .padding(Spacing.md)
                    .background(glassFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .overlay(fieldBorder)
                }
                
                // Website
                formField(label: "Website") {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "globe")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textTertiary)
                        TextField("https://", text: $website)
                            .textFieldStyle(.plain)
                    }
                    .padding(Spacing.md)
                    .background(glassFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .overlay(fieldBorder)
                }
            }
        }
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader(icon: "mappin.circle", title: "Location")
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Street Address
                formField(label: "Street Address") {
                    TextField("123 Wedding Lane, Suite 400", text: $streetAddress)
                        .textFieldStyle(.plain)
                        .padding(Spacing.md)
                        .background(glassFieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .overlay(fieldBorder)
                }
                
                // City & State
                HStack(spacing: Spacing.md) {
                    formField(label: "City") {
                        TextField("San Francisco", text: $city)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(glassFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .overlay(fieldBorder)
                    }
                    
                    formField(label: "State") {
                        TextField("CA", text: $state)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(glassFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .overlay(fieldBorder)
                    }
                }
                
                // Zip & Country
                HStack(spacing: Spacing.md) {
                    formField(label: "Zip Code") {
                        TextField("94103", text: $zipCode)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(glassFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .overlay(fieldBorder)
                    }
                    
                    formField(label: "Country") {
                        Menu {
                            ForEach(countries, id: \.self) { countryOption in
                                Button(countryOption) {
                                    country = countryOption
                                }
                            }
                        } label: {
                            HStack {
                                Text(country)
                                    .foregroundColor(SemanticColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(SemanticColors.textSecondary)
                            }
                            .padding(Spacing.md)
                            .background(glassFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .overlay(fieldBorder)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Social Media Section
    
    private var socialMediaSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader(icon: "link", title: "Social Media")
            
            formField(label: "Instagram Handle") {
                HStack(spacing: Spacing.sm) {
                    Text("@")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textTertiary)
                    TextField("beautybyfuri", text: $instagramHandle)
                        .textFieldStyle(.plain)
                }
                .padding(Spacing.md)
                .background(glassFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay(fieldBorder)
            }
        }
    }
    
    // MARK: - Status & Settings Card
    
    private var statusSettingsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader(icon: "gearshape", title: "Status & Settings", color: SemanticColors.primaryAction)
            
            VStack(spacing: Spacing.lg) {
                // Vendor Booked Toggle
                toggleRow(
                    title: "Vendor Booked",
                    subtitle: "Mark as officially hired",
                    isOn: $isBooked
                )
                
                // Booking Date (shown when booked)
                if isBooked {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Booking Date")
                            .font(Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.Vendor.booked)
                            .textCase(.uppercase)
                        
                        DatePicker("", selection: $dateBooked, displayedComponents: .date)
                            .datePickerStyle(.field)
                            .labelsHidden()
                            .padding(Spacing.sm)
                            .background(AppColors.Vendor.booked.opacity(Opacity.verySubtle))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(AppColors.Vendor.booked.opacity(Opacity.light), lineWidth: 1)
                            )
                    }
                    .padding(Spacing.md)
                    .background(AppColors.Vendor.booked.opacity(Opacity.verySubtle))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                }
                
                Divider()
                
                // Include in Export Toggle
                toggleRow(
                    title: "Include in Export",
                    subtitle: "Show in master timeline PDF",
                    isOn: $includeInExport
                )
                
                // Archived Toggle
                toggleRow(
                    title: "Archived",
                    subtitle: "Hide from active dashboard",
                    isOn: $isArchived
                )
            }
        }
        .padding(Spacing.lg)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .macOSShadow(.subtle)
    }
    
    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(AppColors.Vendor.booked)
        }
    }
    
    // MARK: - Quick Note Card
    
    private var quickNoteCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.statusWarning)
                
                Text("Quick Note")
                    .font(Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.statusWarning)
                    .textCase(.uppercase)
            }
            
            Text(quickNote.isEmpty ? "Add a quick reminder about this vendor..." : quickNote)
                .font(Typography.caption)
                .foregroundColor(quickNote.isEmpty ? SemanticColors.textTertiary : SemanticColors.textSecondary)
                .lineLimit(3)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.statusWarning.opacity(Opacity.verySubtle))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.statusWarning.opacity(Opacity.light), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(icon: String, title: String, color: Color = SemanticColors.textTertiary) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(title.uppercased())
                .font(Typography.caption)
                .fontWeight(.bold)
                .tracking(0.5)
        }
        .foregroundColor(color)
    }
    
    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textSecondary)
            
            content()
        }
    }
    
    private var glassFieldBackground: some View {
        SemanticColors.backgroundPrimary.opacity(0.5)
    }
    
    private var glassCardBackground: some View {
        SemanticColors.backgroundPrimary.opacity(0.4)
    }
    
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .stroke(SemanticColors.borderLight, lineWidth: 1)
    }
}

// MARK: - Preview

#Preview("Overview Tab") {
    ScrollView {
        EditVendorOverviewTabV4(
            vendorName: .constant("Beauty by Furi"),
            vendorType: .constant("Hair & Makeup"),
            priorityLevel: .constant(.medium),
            contactEmail: .constant("hello@beautybyfuri.com"),
            phoneNumber: .constant("+1 (555) 123-4567"),
            website: .constant("https://beautybyfuri.com"),
            streetAddress: .constant("123 Wedding Lane, Suite 400"),
            city: .constant("San Francisco"),
            state: .constant("CA"),
            zipCode: .constant("94103"),
            country: .constant("USA"),
            instagramHandle: .constant("beautybyfuri"),
            isBooked: .constant(true),
            dateBooked: .constant(Date()),
            includeInExport: .constant(true),
            isArchived: .constant(false),
            quickNote: .constant("Remember to ask for the liability insurance certificate before the final payment is released.")
        )
        .padding()
    }
    .frame(width: 850, height: 600)
}
