//
//  LiveCoupleRepository.swift
//  I Do Blueprint
//
//  Production implementation of CoupleRepositoryProtocol
//

import Foundation
import Supabase

/// Helper struct to decode nested membership response from Supabase
private struct MembershipResponse: Codable {
    let id: UUID
    let coupleId: UUID
    let userId: UUID
    let role: String
    let createdAt: Date
    let updatedAt: Date
    let coupleProfiles: CoupleProfileNested

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case userId = "user_id"
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleProfiles = "couple_profiles"
    }

    struct CoupleProfileNested: Codable {
        let partner1Name: String
        let partner2Name: String?
        let weddingDate: Date?

        enum CodingKeys: String, CodingKey {
            case partner1Name = "partner1_name"
            case partner2Name = "partner2_name"
            case weddingDate = "wedding_date"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            partner1Name = try container.decode(String.self, forKey: .partner1Name)
            partner2Name = try container.decodeIfPresent(String.self, forKey: .partner2Name)

            // Custom date decoding to handle "YYYY-MM-DD" format from Supabase
            if let dateString = try container.decodeIfPresent(String.self, forKey: .weddingDate) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                weddingDate = formatter.date(from: dateString)
            } else {
                weddingDate = nil
            }
        }
    }
}

/// Production implementation of CoupleRepositoryProtocol
actor LiveCoupleRepository: CoupleRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let cache: RepositoryCache

    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase
        cache = RepositoryCache()
    }

    // Convenience initializer using SupabaseManager
    init() {
        supabase = SupabaseManager.shared.client
        cache = RepositoryCache()
    }

    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    func fetchCouplesForUser(userId: UUID) async throws -> [CoupleMembership] {
        let cacheKey = "couples_\(userId.uuidString)"

        // Return cached data if available and less than 5 minutes old
        if let cached: [CoupleMembership] = await cache.get(cacheKey, maxAge: 300) {
            return cached
        }

        let client = try getClient()

        // Query collaborators table (new collaboration system) joined with couple_profiles
        // Note: We need to manually decode since Supabase nested joins don't map directly to flat models
        do {
            AppLogger.repository.info("Querying collaborators for user \(userId)")

            // Helper struct for decoding collaborators response
            struct CollaboratorResponse: Codable {
                let id: UUID
                let coupleId: UUID
                let userId: UUID
                let roleId: UUID
                let status: String
                let createdAt: Date
                let updatedAt: Date
                let coupleProfiles: CoupleProfileNested

                enum CodingKeys: String, CodingKey {
                    case id
                    case coupleId = "couple_id"
                    case userId = "user_id"
                    case roleId = "role_id"
                    case status
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                    case coupleProfiles = "couple_profiles"
                }

                struct CoupleProfileNested: Codable {
                    let partner1Name: String
                    let partner2Name: String?
                    let weddingDate: Date?

                    enum CodingKeys: String, CodingKey {
                        case partner1Name = "partner1_name"
                        case partner2Name = "partner2_name"
                        case weddingDate = "wedding_date"
                    }

                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        partner1Name = try container.decode(String.self, forKey: .partner1Name)
                        partner2Name = try container.decodeIfPresent(String.self, forKey: .partner2Name)

                        // Custom date decoding to handle "YYYY-MM-DD" format from Supabase
                        if let dateString = try container.decodeIfPresent(String.self, forKey: .weddingDate) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            formatter.locale = Locale(identifier: "en_US_POSIX")
                            formatter.timeZone = TimeZone(secondsFromGMT: 0)
                            weddingDate = formatter.date(from: dateString)
                        } else {
                            weddingDate = nil
                        }
                    }
                }
            }

            // Query collaborators table
            let response: [CollaboratorResponse] = try await client
                .from("collaborators")
                .select("""
                    id,
                    couple_id,
                    user_id,
                    role_id,
                    status,
                    created_at,
                    updated_at,
                    couple_profiles!inner(
                        partner1_name,
                        partner2_name,
                        wedding_date
                    )
                """)
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
                .value

            AppLogger.repository.info("Successfully decoded \(response.count) collaborators")

            // Fetch role names for each collaborator
            let roleIds = response.map { $0.roleId }
            let roles: [CollaborationRole] = try await client
                .from("collaboration_roles")
                .select()
                .in("id", values: roleIds)
                .execute()
                .value

            // Create role lookup dictionary
            let roleDict = Dictionary(uniqueKeysWithValues: roles.map { ($0.id, $0.roleName.rawValue) })

            // Map to CoupleMembership by flattening the nested couple_profiles
            let couples = response.map { collaborator in
                CoupleMembership(
                    id: collaborator.id,
                    coupleId: collaborator.coupleId,
                    userId: collaborator.userId,
                    role: roleDict[collaborator.roleId] ?? "member",
                    createdAt: collaborator.createdAt,
                    updatedAt: collaborator.updatedAt,
                    partner1Name: collaborator.coupleProfiles.partner1Name,
                    partner2Name: collaborator.coupleProfiles.partner2Name,
                    weddingDate: collaborator.coupleProfiles.weddingDate
                )
            }

            // Store in cache for future requests
            await cache.set(cacheKey, value: couples)

            AppLogger.repository.info("Fetched \(couples.count) couples for user \(userId)")

            return couples
        } catch let decodingError as DecodingError {
            // Log detailed decoding error information
            AppLogger.repository.error("=== DECODING ERROR ===")
            switch decodingError {
            case .keyNotFound(let key, let context):
                AppLogger.repository.error("Missing key: '\(key.stringValue)'")
                AppLogger.repository.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                AppLogger.repository.error("Debug description: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                AppLogger.repository.error("Type mismatch for: \(type)")
                AppLogger.repository.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                AppLogger.repository.error("Debug description: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                AppLogger.repository.error("Value not found for: \(type)")
                AppLogger.repository.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                AppLogger.repository.error("Debug description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                AppLogger.repository.error("Data corrupted")
                AppLogger.repository.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                AppLogger.repository.error("Debug description: \(context.debugDescription)")
            @unknown default:
                AppLogger.repository.error("Unknown decoding error: \(decodingError)")
            }
            throw decodingError
        } catch {
            AppLogger.repository.error("=== NON-DECODING ERROR ===")
            AppLogger.repository.error("Error type: \(type(of: error))")
            AppLogger.repository.error("Error: \(error)")
            AppLogger.repository.error("Localized: \(error.localizedDescription)")
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchCouplesForUser",
                "repository": "LiveCoupleRepository",
                "userId": userId.uuidString
            ])
            throw error
        }
    }
}
