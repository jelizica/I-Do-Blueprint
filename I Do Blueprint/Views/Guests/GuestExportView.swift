//
//  GuestExportView.swift
//  I Do Blueprint
//
//  Export sheet for guest list
//

import SwiftUI

struct GuestExportView: View {
    let guests: [Guest]
    let settings: CoupleSettings
    let onExportSuccessful: ((URL, GuestExportFormat) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: GuestExportFormat = .csv
    @State private var isExporting = false
    @State private var exportError: Error?
    
    private let logger = AppLogger.export
    
    init(
        guests: [Guest],
        settings: CoupleSettings,
        onExportSuccessful: ((URL, GuestExportFormat) -> Void)? = nil
    ) {
        self.guests = guests
        self.settings = settings
        self.onExportSuccessful = onExportSuccessful
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Guest List")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.xl)
            .background(AppColors.cardBackground)
            
            Divider()
                .background(AppColors.borderLight)
            
            // Content
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Guest count info
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                        
                        Text("\(guests.count) guests will be exported")
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(CornerRadius.lg)
                    
                    // Format selection
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Export Format")
                            .font(Typography.heading)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ForEach(GuestExportFormat.allCases, id: \.self) { format in
                            FormatOptionCard(
                                format: format,
                                isSelected: selectedFormat == format,
                                onSelect: { selectedFormat = format }
                            )
                        }
                    }
                    
                    // Error message
                    if let error = exportError {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.error)
                            
                            Text(error.localizedDescription)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.error)
                            
                            Spacer()
                        }
                        .padding(Spacing.lg)
                        .background(AppColors.errorLight)
                        .cornerRadius(CornerRadius.lg)
                    }
                }
                .padding(Spacing.xl)
            }
            
            Divider()
                .background(AppColors.borderLight)
            
            // Footer with action buttons
            HStack(spacing: Spacing.md) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.borderLight, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    Task {
                        await performExport()
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(AppColors.textPrimary)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                        }
                        
                        Text(isExporting ? "Exporting..." : "Export")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(isExporting || guests.isEmpty)
            }
            .padding(Spacing.xl)
            .background(AppColors.cardBackground)
        }
        .frame(width: 500, height: 600)
        .background(AppColors.background)
    }
    
    // MARK: - Export Logic
    
    @MainActor
    private func performExport() async {
        isExporting = true
        exportError = nil
        
        do {
            let fileURL = try await GuestExportService.shared.exportGuests(
                guests,
                settings: settings,
                format: selectedFormat
            )
            
            logger.info("Successfully exported \(guests.count) guests as \(selectedFormat.rawValue)")
            
            // Call completion handler first while view is in stable state
            onExportSuccessful?(fileURL, selectedFormat)
            
            // Then dismiss modal
            dismiss()
            
        } catch {
            exportError = error
            isExporting = false
            
            logger.error("Failed to export guests", error: error)
            
            // Show error alert
            GuestExportService.shared.showExportErrorAlert(error: error)
        }
    }
}

// MARK: - Format Option Card

private struct FormatOptionCard: View {
    let format: GuestExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: format.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 40)
                
                // Format info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(format.rawValue)
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(formatDescription(for: format))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                } else {
                    Circle()
                        .stroke(AppColors.borderLight, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(Spacing.lg)
            .background(isSelected ? AppColors.primaryLight : AppColors.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isSelected ? AppColors.primary : AppColors.borderLight, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatDescription(for format: GuestExportFormat) -> String {
        switch format {
        case .csv:
            return "Spreadsheet format compatible with Excel, Numbers, and Google Sheets"
        case .pdf:
            return "Formatted document with guest cards, perfect for printing"
        case .googleSheets:
            return "Export directly to Google Sheets (requires Google account)"
        }
    }
}

// MARK: - Preview

#Preview {
    GuestExportView(
        guests: [
            Guest(
                id: UUID(),
                createdAt: Date(),
                updatedAt: Date(),
                firstName: "John",
                lastName: "Doe",
                email: "john@example.com",
                phone: "555-1234",
                guestGroupId: nil,
                relationshipToCouple: nil,
                invitedBy: .bride1,
                rsvpStatus: .confirmed,
                rsvpDate: nil,
                plusOneAllowed: true,
                plusOneName: "Jane Doe",
                plusOneAttending: true,
                attendingCeremony: true,
                attendingReception: true,
                attendingOtherEvents: nil,
                dietaryRestrictions: "Vegetarian",
                accessibilityNeeds: nil,
                tableAssignment: 5,
                seatNumber: nil,
                preferredContactMethod: nil,
                addressLine1: "123 Main St",
                addressLine2: nil,
                city: "Springfield",
                state: "IL",
                zipCode: "62701",
                country: nil,
                invitationNumber: nil,
                isWeddingParty: false,
                weddingPartyRole: nil,
                preparationNotes: nil,
                coupleId: UUID(),
                mealOption: "Chicken",
                giftReceived: false,
                notes: "VIP guest",
                hairDone: false,
                makeupDone: false
            )
        ],
        settings: CoupleSettings(
            global: GlobalSettings(
                currency: "USD",
                weddingDate: "2026-08-11",
                isWeddingDateTBD: false,
                timezone: "America/New_York",
                partner1FullName: "Alice",
                partner1Nickname: "",
                partner2FullName: "Bob",
                partner2Nickname: "",
                weddingEvents: []
            ),
            theme: .default,
            budget: .default,
            cashFlow: .default,
            tasks: .default,
            vendors: .default,
            guests: .default,
            documents: .default,
            notifications: .default,
            links: .default
        )
    )
}
