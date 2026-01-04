//
//  VendorDetailModalV6.swift
//  I Do Blueprint
//
//  V6 Modal for displaying vendor details with native macOS styling:
//  - Proper light/dark mode support
//  - Native materials and vibrancy
//  - Gradient borders and multi-layer shadows
//  - Enhanced visual hierarchy
//

import SwiftUI
import Dependencies

struct VendorDetailModalV6: View {
    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0
    @State private var showingEditSheet = false
    @State private var loadedImage: NSImage?
    @State private var hasAppeared = false

    // Financial data
    @State private var expenses: [Expense] = []
    @State private var payments: [PaymentSchedule] = []
    @State private var isLoadingFinancials = false
    @State private var financialLoadError: Error?

    // Documents data
    @State private var documents: [Document] = []
    @State private var isLoadingDocuments = false
    @State private var documentLoadError: Error?

    @Dependency(\.budgetRepository) var budgetRepository
    @Dependency(\.documentRepository) var documentRepository

    private let logger = AppLogger.ui

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header with V6 Styling
            VStack(spacing: 0) {
                HStack(spacing: Spacing.lg) {
                    // Vendor Icon with enhanced styling
                    vendorIcon
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : -10)
                        .animation(.easeOut(duration: 0.4), value: hasAppeared)
                    
                    // Vendor Info
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(vendor.vendorName)
                            .font(Typography.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(nsColor: .labelColor))
                        
                        HStack(spacing: Spacing.sm) {
                            if let type = vendor.vendorType {
                                Text(type)
                                    .font(Typography.caption)
                                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                            }
                            
                            if vendor.isBooked == true {
                                Text("•")
                                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Booked")
                                        .font(Typography.caption2.weight(.medium))
                                }
                                .foregroundColor(AppColors.Vendor.booked)
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -10)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
                    
                    Spacer()
                    
                    // Action Buttons with V6 styling
                    HStack(spacing: Spacing.sm) {
                        Button {
                            onEdit()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SemanticColors.primaryAction)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(SemanticColors.primaryAction.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibleActionButton(label: "Edit vendor", hint: "Opens edit form", isDestructive: false)
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibleActionButton(label: "Close modal", hint: "Closes vendor details", isDestructive: false)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -10)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)
                }
                .padding(Spacing.xl)
                .background(.regularMaterial)
                
                NativeDividerStyle(opacity: 0.4)
            }

            // MARK: - Tab Bar with V6 Styling
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(tab.title)
                                    .font(Typography.caption.weight(.semibold))
                            }
                            .foregroundColor(selectedTab == index ? SemanticColors.primaryAction : Color(nsColor: .secondaryLabelColor))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            
                            // Active indicator
                            Rectangle()
                                .fill(selectedTab == index ? SemanticColors.primaryAction : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.ultraThinMaterial)
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)
            
            NativeDividerStyle(opacity: 0.3)

            // MARK: - Content with V6 Styling
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch selectedTab {
                    case 0:
                        VendorDetailOverviewTab(vendor: vendor)
                    case 1:
                        VendorDetailFinancialTab(
                            vendor: vendor,
                            expenses: expenses,
                            payments: payments,
                            isLoading: isLoadingFinancials
                        )
                    case 2:
                        VendorDetailDocumentsTab(
                            documents: documents,
                            isLoading: isLoadingDocuments
                        )
                    case 3:
                        VendorDetailNotesTab(vendor: vendor)
                    default:
                        EmptyView()
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(.regularMaterial)
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV2(vendor: vendor, vendorStore: vendorStore) { _ in
                // Reload will happen automatically through the store
            }
        }
        .task {
            await loadVendorImage()
            await loadFinancialData()
            await loadDocuments()
        }
        .onAppear {
            logger.info("VendorDetailModalV6 appeared for vendor: \(vendor.vendorName)")
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Vendor Icon
    
    private var vendorIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientForVendorType(vendor.vendorType ?? ""),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            } else {
                Image(systemName: iconForVendorType(vendor.vendorType ?? ""))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }
    
    // MARK: - Tab Configuration
    
    private var tabs: [(title: String, icon: String)] {
        [
            ("Overview", "info.circle"),
            ("Financial", "dollarsign.circle"),
            ("Documents", "doc.text"),
            ("Notes", "note.text")
        ]
    }
    
    // MARK: - Actions
    
    private func onEdit() {
        showingEditSheet = true
    }

    // MARK: - Image Loading

    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            loadedImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    loadedImage = nsImage
                }
            }
        } catch {
            logger.error("Failed to load vendor image from URL: \(imageUrl)", error: error)
            await MainActor.run {
                loadedImage = nil
            }
        }
    }

    // MARK: - Data Loading

    private func loadFinancialData() async {
        isLoadingFinancials = true
        financialLoadError = nil

        do {
            async let expensesTask = budgetRepository.fetchExpensesByVendor(vendorId: vendor.id)
            async let paymentsTask = budgetRepository.fetchPaymentSchedulesByVendor(vendorId: vendor.id)

            expenses = try await expensesTask
            payments = try await paymentsTask

            logger.info("Loaded financial data for vendor \(vendor.vendorName): \(expenses.count) expenses, \(payments.count) payments")
        } catch {
            financialLoadError = error
            logger.error("Error loading financial data for vendor \(vendor.id)", error: error)
        }

        isLoadingFinancials = false
    }

    private func loadDocuments() async {
        isLoadingDocuments = true
        documentLoadError = nil

        do {
            documents = try await documentRepository.fetchDocuments(vendorId: Int(vendor.id))
            logger.info("Loaded \(documents.count) documents for vendor \(vendor.vendorName)")
        } catch {
            documentLoadError = error
            logger.error("Error loading documents for vendor \(vendor.id)", error: error)
        }

        isLoadingDocuments = false
    }
    
    // MARK: - Helper Functions
    
    private func iconForVendorType(_ type: String) -> String {
        switch type.lowercased() {
        case "venue": return "mappin.circle.fill"
        case "photography", "photographer": return "camera.fill"
        case "catering", "caterer": return "fork.knife"
        case "music", "dj", "band": return "music.note"
        case "florist", "flowers": return "leaf.fill"
        default: return "briefcase.fill"
        }
    }
    
    private func gradientForVendorType(_ type: String) -> [Color] {
        switch type.lowercased() {
        case "venue": return [Color.fromHex("EC4899"), Color.fromHex("F43F5E")]
        case "photography", "photographer": return [Color.fromHex("A855F7"), Color.fromHex("EC4899")]
        case "catering", "caterer": return [Color.fromHex("F97316"), Color.fromHex("EC4899")]
        case "music", "dj", "band": return [Color.fromHex("3B82F6"), Color.fromHex("A855F7")]
        case "florist", "flowers": return [Color.fromHex("10B981"), Color.fromHex("059669")]
        default: return [Color.fromHex("6366F1"), Color.fromHex("8B5CF6")]
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    VendorDetailModalV6(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Elegant Events Co.",
            vendorType: "Event Planner",
            vendorCategoryId: nil,
            contactName: "Sarah Johnson",
            phoneNumber: "+1 (555) 987-6543",
            email: "sarah@elegantevents.com",
            website: "https://elegantevents.com",
            notes: "Specializes in luxury weddings. Has excellent portfolio and great reviews.",
            quotedAmount: 5000,
            imageUrl: nil,
            isBooked: true,
            dateBooked: Date(),
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        vendorStore: VendorStoreV2()
    )
    .frame(width: 800, height: 700)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VendorDetailModalV6(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Elegant Events Co.",
            vendorType: "Event Planner",
            vendorCategoryId: nil,
            contactName: "Sarah Johnson",
            phoneNumber: "+1 (555) 987-6543",
            email: "sarah@elegantevents.com",
            website: "https://elegantevents.com",
            notes: "Specializes in luxury weddings. Has excellent portfolio and great reviews.",
            quotedAmount: 5000,
            imageUrl: nil,
            isBooked: true,
            dateBooked: Date(),
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        vendorStore: VendorStoreV2()
    )
    .frame(width: 800, height: 700)
    .preferredColorScheme(.dark)
}
