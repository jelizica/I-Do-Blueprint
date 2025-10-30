//
//  CoupleSwitcherMenu.swift
//  I Do Blueprint
//
//  Menu for switching between accessible couples
//

import SwiftUI

struct CoupleSwitcherMenu: View {
    @EnvironmentObject private var appStores: AppStores
    @State private var couples: [CoupleMembership] = []
    @State private var isLoading = false
    @State private var error: String?
    
    private let logger = AppLogger.ui
    private let sessionManager = SessionManager.shared
    
    var body: some View {
        Menu {
            if isLoading {
                Text("Loading couples...")
                    .disabled(true)
            } else if let error = error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if couples.isEmpty {
                Text("No couples available")
                    .disabled(true)
            } else {
                ForEach(couples) { couple in
                    Button {
                        Task {
                            await switchToCouple(couple)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(couple.displayName)
                                    .font(Typography.bodyRegular)
                                
                                if let weddingDate = couple.weddingDate {
                                    Text(formatWeddingDate(weddingDate))
                                        .font(Typography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if couple.coupleId == currentCoupleId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                            
                            Text(couple.role)
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .disabled(couple.coupleId == currentCoupleId)
                }
                
                Divider()
                
                Button {
                    // Navigate to couple management/creation
                    logger.info("User wants to create new couple")
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create New Couple")
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                
                Text(currentCoupleName)
                    .font(Typography.bodyRegular)
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
        }
        .menuStyle(.borderlessButton)
        .task {
            await loadCouples()
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentCoupleId: UUID? {
        sessionManager.currentTenantId
    }
    
    private var currentCoupleName: String {
        if let currentId = currentCoupleId,
           let couple = couples.first(where: { $0.coupleId == currentId }) {
            return couple.displayName
        }
        return "Select Couple"
    }
    
    // MARK: - Actions
    
    private func loadCouples() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        logger.info("Loading accessible couples for user")
        
        do {
            // Get current user ID
            guard let userId = try? await MainActor.run(body: {
                try AuthContext.shared.requireUserId()
            }) else {
                throw NSError(domain: "CoupleSwitcher", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "User not authenticated"
                ])
            }
            
            // Fetch couples from repository
            let repository = LiveCoupleRepository()
            let fetchedCouples = try await repository.fetchCouplesForUser(userId: userId)
            
            await MainActor.run {
                self.couples = fetchedCouples
                self.isLoading = false
            }
            
            logger.info("Loaded \(fetchedCouples.count) accessible couples")
            
        } catch {
            logger.error("Failed to load couples", error: error)
            await MainActor.run {
                self.error = "Failed to load couples"
                self.isLoading = false
            }
            
            await SentryService.shared.captureError(error, context: [
                "operation": "loadCouples"
            ])
        }
    }
    
    private func switchToCouple(_ couple: CoupleMembership) async {
        logger.info("Switching to couple: \(couple.displayName) (\(couple.coupleId.uuidString))")
        
        // Update session manager (async call)
        // Note: setTenantId() already calls resetAllStores(), so we don't need to call it again
        await sessionManager.setTenantId(
            couple.coupleId,
            coupleName: couple.displayName,
            weddingDate: couple.weddingDate
        )
        
        logger.info("Switched to couple: \(couple.displayName)")
        
        // Track couple switch
        await SentryService.shared.trackAction(
            "couple_switched",
            category: "navigation",
            metadata: [
                "couple_id": couple.coupleId.uuidString,
                "couple_name": couple.displayName,
                "role": couple.role
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatWeddingDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Couple Switcher") {
    CoupleSwitcherMenu()
        .environmentObject(AppStores.shared)
        .padding()
}
