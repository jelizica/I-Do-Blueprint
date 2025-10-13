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
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var couples: [CoupleMembership] = []

    private let coupleRepository = LiveCoupleRepository()

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
            .padding(.horizontal, 40)
            .padding(.top, 20)

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
                .padding(.horizontal, 40)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(couples) { couple in
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
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading)
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
                .padding(.horizontal, 40)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .frame(width: 500, height: 400)
        .padding()
        .task {
            await loadCouples()
        }
    }

    private func loadCouples() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID from Supabase auth
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            couples = try await coupleRepository.fetchCouplesForUser(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Failed to load couples: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func selectCouple(_ couple: CoupleMembership) {
        isLoading = true
        errorMessage = nil

        Task {
            await sessionManager.setTenantId(couple.coupleId)

            await MainActor.run {
                isLoading = false
                // View will automatically hide when tenantId is set (via ContentView observation)
            }
        }
    }

    private func createNewCouple() {
        isLoading = true
        errorMessage = nil

        Task {
            // TODO: Implement couple creation workflow
            // This should navigate to a couple profile creation form
            await MainActor.run {
                isLoading = false
                errorMessage = "Couple creation is not yet implemented"
            }
        }
    }
}

#Preview {
    TenantSelectionView()
}
