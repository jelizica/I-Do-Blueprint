//
//  TenantSelectionView.swift
//  I Do Blueprint
//
//  Tenant/couple selection after login
//

import SwiftUI
import Auth
import Supabase

struct TenantSelectionView: View {
    private let logger = AppLogger.auth
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var couples: [CoupleMembership] = []
    @State private var showingCoupleCreation = false
    
    // Phase 3.3: Search & Filter
    @State private var searchText = ""
    @State private var sortOption: SortOption = .recent
    
    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case name = "Name"
        case date = "Wedding Date"
    }

    private let coupleRepository = LiveCoupleRepository()
    
    // Phase 3.3: Filtered and sorted couples
    private var filteredCouples: [CoupleMembership] {
        var result = couples
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { couple in
                couple.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortOption {
        case .recent:
            // Sort by recent first (if in recent list), then by name
            result.sort { couple1, couple2 in
                let isRecent1 = sessionManager.recentCouples.contains { $0.id == couple1.coupleId }
                let isRecent2 = sessionManager.recentCouples.contains { $0.id == couple2.coupleId }
                
                if isRecent1 && !isRecent2 {
                    return true
                } else if !isRecent1 && isRecent2 {
                    return false
                } else {
                    return couple1.displayName < couple2.displayName
                }
            }
        case .name:
            result.sort { $0.displayName < $1.displayName }
        case .date:
            result.sort { couple1, couple2 in
                guard let date1 = couple1.weddingDate else { return false }
                guard let date2 = couple2.weddingDate else { return true }
                return date1 < date2
            }
        }
        
        return result
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header with logout button
            HStack {
                Spacer()
                Button(action: {
                    Task {
                        try? await supabaseManager.signOut()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.huge)
            .padding(.top, Spacing.xl)

            // Header
            VStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)

                Text("Select Your Wedding")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choose which wedding you'd like to manage")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // Couples list
            if couples.isEmpty && !isLoading {
                VStack(spacing: 16) {
                    Text("No weddings found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        createNewCouple()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Wedding")
                        }
                        .foregroundColor(.blue)
                        .padding()
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(.horizontal, Spacing.huge)
            } else {
                VStack(spacing: 12) {
                    // Phase 3.3: Search and Sort Controls
                    if couples.count > 3 {
                        VStack(spacing: 8) {
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Search weddings...", text: $searchText)
                                    .textFieldStyle(.plain)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(Spacing.sm)
                            .background(AppColors.textSecondary.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Sort options
                            HStack(spacing: 8) {
                                Text("Sort by:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOption = option
                                    }) {
                                        Text(option.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, Spacing.xs)
                                            .background(sortOption == option ? Color.blue : AppColors.textSecondary.opacity(0.1))
                                            .foregroundColor(sortOption == option ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, Spacing.huge)
                    }
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Phase 3.2: Recently Viewed Section
                            if !sessionManager.recentCouples.isEmpty && searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Recently Viewed")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, Spacing.xs)
                                
                                ForEach(sessionManager.recentCouples) { recent in
                                    Button(action: {
                                        selectRecentCouple(recent)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(recent.displayName)
                                                    .font(.headline)
                                                if let weddingDate = recent.weddingDate {
                                                    Text(weddingDate, style: .date)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isLoading)
                                }
                            }
                            
                            Divider()
                                    .padding(.vertical, Spacing.sm)
                            }
                        }
                        
                        // All Couples Section
                        if !sessionManager.recentCouples.isEmpty && searchText.isEmpty {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("All Weddings")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, Spacing.xs)
                        }
                        
                        // Phase 3.3: Use filtered and sorted couples
                        if filteredCouples.isEmpty && !searchText.isEmpty {
                            // No search results
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No weddings found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Try a different search term")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, Spacing.huge)
                        } else {
                            ForEach(filteredCouples) { couple in
                                Button(action: {
                                    selectCouple(couple)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(couple.displayName)
                                                .font(.headline)
                                            if let weddingDate = couple.weddingDate {
                                                Text(weddingDate, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(AppColors.textSecondary.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                            }
                        }

                        Button(action: {
                            createNewCouple()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Wedding")
                            }
                            .foregroundColor(.blue)
                            .padding()
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, Spacing.huge)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .frame(width: 500, height: 400)
        .padding()
        .sheet(isPresented: $showingCoupleCreation) {
            CoupleCreationView(onComplete: {
                Task {
                    await loadCouples()
                }
            })
        }
        .overlay {
            // Phase 3.1: Show loading overlay during tenant switch
            if sessionManager.isSwitchingTenant,
               let coupleName = sessionManager.switchingToCoupleName {
                TenantSwitchLoadingView(coupleName: coupleName)
            }
        }
        .task {
            await loadCouples()
        }
    }

    private func loadCouples() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID from Supabase auth
            guard let client = SupabaseManager.shared.client else {
                await MainActor.run {
                    errorMessage = "Configuration error: Unable to connect to database. Please check your settings."
                    isLoading = false
                }
                return
            }
            
            let session = try await client.auth.session
            let userId = session.user.id
            
            logger.debug("Loading couples for user: \(userId)")

            couples = try await coupleRepository.fetchCouplesForUser(userId: userId)
            
            logger.debug("Found \(couples.count) couples")
            for couple in couples {
                logger.debug("Couple: \(couple.displayName) (ID: \(couple.coupleId))")
            }
            
            isLoading = false
        } catch {
            logger.error("Error loading couples: \(error)")
            errorMessage = "Failed to load couples: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func selectCouple(_ couple: CoupleMembership) {
        errorMessage = nil
        
        logger.info("User selected couple: \(couple.displayName) (ID: \(couple.coupleId))")

        Task {
            // Pass couple name and wedding date for visual feedback (Phase 3.1) and recent tracking (Phase 3.2)
            await sessionManager.setTenantId(
                couple.coupleId, 
                coupleName: couple.displayName,
                weddingDate: couple.weddingDate
            )
            
            logger.info("Tenant ID set to: \(couple.coupleId)")

            // View will automatically hide when tenantId is set (via RootFlowView observation)
        }
    }
    
    private func selectRecentCouple(_ recent: RecentCouple) {
        errorMessage = nil
        
        logger.info("User selected recent couple: \(recent.displayName) (ID: \(recent.id))")

        Task {
            await sessionManager.setTenantId(
                recent.id,
                coupleName: recent.displayName,
                weddingDate: recent.weddingDate
            )
            
            logger.info("Tenant ID set to: \(recent.id)")
        }
    }

    private func createNewCouple() {
        showingCoupleCreation = true
    }
}

#Preview {
    TenantSelectionView()
}
