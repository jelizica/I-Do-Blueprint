//
//  CoupleCreationView.swift
//  I Do Blueprint
//
//  View for creating a new couple/wedding profile
//

import SwiftUI
import Supabase

struct CoupleCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = SessionManager.shared

    @State private var partner1Name: String = ""
    @State private var partner2Name: String = ""
    @State private var weddingDate: Date = Date()
    @State private var hasWeddingDate: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var onComplete: (() -> Void)?

    private let logger = AppLogger.auth

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)

                    Text("Create Your Wedding")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Let's set up your wedding planning workspace")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.xxl)

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

                // Form
                Form {
                    Section {
                        TextField("Partner 1 Name", text: $partner1Name)
                            .textFieldStyle(.roundedBorder)

                        TextField("Partner 2 Name (Optional)", text: $partner2Name)
                            .textFieldStyle(.roundedBorder)
                    } header: {
                        Text("Couple Information")
                            .font(.headline)
                    }

                    Section {
                        Toggle("Set Wedding Date", isOn: $hasWeddingDate)

                        if hasWeddingDate {
                            DatePicker(
                                "Wedding Date",
                                selection: $weddingDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                        }
                    } header: {
                        Text("Wedding Details")
                            .font(.headline)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)

                Spacer()

                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)

                    Button("Create Wedding") {
                        Task {
                            await createCouple()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(partner1Name.isEmpty || isLoading)
                }
                .padding(.bottom, Spacing.xxl)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            .frame(width: 600, height: 700)
            .navigationTitle("New Wedding")
        }
    }

    private func createCouple() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID
            let userId = try AuthContext.shared.requireUserId()

            // Create couple profile
            let coupleId = UUID()

            guard let supabase = SupabaseManager.shared.client else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Configuration error: Unable to connect to database. Please check your settings."
                }
                logger.error("Supabase client not available")
                return
            }

            // Format wedding date as YYYY-MM-DD for date column
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            // Create couple profile data structure
            struct CoupleProfileInsert: Encodable {
                let id: String
                let partner1_name: String
                let partner2_name: String?
                let wedding_date: String?
            }

            let coupleData = CoupleProfileInsert(
                id: coupleId.uuidString,
                partner1_name: partner1Name,
                partner2_name: partner2Name.isEmpty ? nil : partner2Name,
                wedding_date: hasWeddingDate ? dateFormatter.string(from: weddingDate) : nil
            )

            try await supabase
                .from("couple_profiles")
                .insert(coupleData)
                .execute()

            logger.info("Created couple profile: \(coupleId)")

            // Create membership data structure
            struct MembershipInsert: Encodable {
                let couple_id: String
                let user_id: String
                let role: String
            }

            let membershipData = MembershipInsert(
                couple_id: coupleId.uuidString,
                user_id: userId.uuidString,
                role: "admin"
            )

            try await supabase
                .from("memberships")
                .insert(membershipData)
                .execute()

            logger.info("Created membership for user: \(userId)")

            // Set as active couple
            await sessionManager.setTenantId(coupleId)

            // Refresh auth context
            await AuthContext.shared.refresh()

            await MainActor.run {
                isLoading = false
                dismiss()
            }

        } catch {
            logger.error("Failed to create couple", error: error)
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to create wedding: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    CoupleCreationView()
}
