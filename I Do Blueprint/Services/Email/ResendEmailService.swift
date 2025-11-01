//
//  ResendEmailService.swift
//  I Do Blueprint
//
//  Email service using Resend API for collaboration invitations
//

import Foundation
import Combine

/// Service for sending emails via Resend API
@MainActor
final class ResendEmailService: ObservableObject {
    static let shared = ResendEmailService()

    private let logger = AppLogger.api
    private let baseURL = "https://api.resend.com"
    private let apiKeyManager = SecureAPIKeyManager.shared

    // Embedded API key for shared email service
    // Users can optionally override this with their own key in Settings
    private let embeddedAPIKey = "re_5tuxAHLr_3LtMhuJ2de7d6Awh2aLyTjup"

    // MARK: - Published State

    @Published var isSending = false
    @Published var lastError: EmailError?

    // MARK: - Invitation Email

    /// Send a collaboration invitation email
    /// - Parameters:
    ///   - to: Recipient email address
    ///   - inviterName: Name of person sending invitation
    ///   - coupleName: Name of the couple (e.g., "Jessica & Partner")
    ///   - role: Role being offered (e.g., "Planner", "Viewer")
    ///   - token: Invitation token for the deep link
    ///   - expiresAt: When the invitation expires
    func sendInvitationEmail(
        to email: String,
        inviterName: String,
        coupleName: String,
        role: String,
        token: String,
        expiresAt: Date
    ) async throws {
        // Try to get user's custom API key, fall back to embedded key
        let apiKey: String
        if let userKey = apiKeyManager.getAPIKey(for: .resend), !userKey.isEmpty {
            logger.debug("Using user-provided Resend API key")
            apiKey = userKey
        } else {
            logger.debug("Using embedded shared Resend API key")
            apiKey = embeddedAPIKey
        }

        isSending = true
        defer { isSending = false }

        do {
            let invitationURL = generateInvitationURL(token: token)
            let expiryDescription = formatExpiryDate(expiresAt)

            let emailPayload = ResendEmailPayload(
                from: "I Do Blueprint <invitations@idoblueprint.app>",
                to: [email],
                subject: "\(inviterName) invited you to collaborate on \(coupleName)'s wedding",
                html: generateInvitationHTML(
                    inviterName: inviterName,
                    coupleName: coupleName,
                    role: role,
                    invitationURL: invitationURL,
                    expiryDescription: expiryDescription
                )
            )

            try await sendEmail(payload: emailPayload, apiKey: apiKey)

            logger.info("Successfully sent invitation email to \(email)")

        } catch {
            logger.error("Failed to send invitation email", error: error)
            lastError = error as? EmailError ?? .sendFailed(underlying: error)

            await SentryService.shared.captureError(error, context: [
                "operation": "sendInvitationEmail",
                "recipient": email,
                "role": role
            ])

            throw error
        }
    }

    // MARK: - HTTP Request

    private func sendEmail(payload: ResendEmailPayload, apiKey: String) async throws {
        guard let url = URL(string: "\(baseURL)/emails") else {
            throw EmailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmailError.invalidResponse
        }

        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("Resend API response: \(responseString)")
        }

        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response to get email ID
            if let emailResponse = try? JSONDecoder().decode(ResendEmailResponse.self, from: data) {
                logger.info("Email sent successfully with ID: \(emailResponse.id)")
            }

        case 400:
            logger.error("Bad request to Resend API")
            throw EmailError.badRequest(message: "Invalid email payload")

        case 401:
            logger.error("Resend API key is invalid or expired")
            throw EmailError.unauthorized

        case 429:
            logger.error("Resend API rate limit exceeded")
            throw EmailError.rateLimitExceeded

        default:
            logger.error("Resend API returned status code: \(httpResponse.statusCode)")
            throw EmailError.sendFailed(underlying: NSError(
                domain: "ResendAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
            ))
        }
    }

    // MARK: - URL Generation

    private func generateInvitationURL(token: String) -> String {
        #if DEBUG
        // Development: Use custom URL scheme for reliable testing
        // This opens the app directly without requiring AASA file or TestFlight
        "idoblueprint://accept-invitation?token=\(token)"
        #else
        // Production: Use Universal Link (requires AASA file + App Store distribution)
        // Falls back to custom URL scheme if app not installed
        "https://idoblueprint.app/accept-invitation?token=\(token)"
        #endif
    }

    // MARK: - HTML Template

    private func generateInvitationHTML(
        inviterName: String,
        coupleName: String,
        role: String,
        invitationURL: String,
        expiryDescription: String
    ) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Wedding Planning Invitation</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f5f5f5;
                }
                .container {
                    background-color: white;
                    border-radius: 12px;
                    padding: 40px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                }
                .header h1 {
                    color: #6B46C1;
                    font-size: 28px;
                    margin: 0 0 10px 0;
                }
                .invitation-details {
                    background-color: #F7FAFC;
                    border-left: 4px solid #6B46C1;
                    padding: 20px;
                    margin: 20px 0;
                    border-radius: 4px;
                }
                .invitation-details p {
                    margin: 8px 0;
                }
                .invitation-details strong {
                    color: #6B46C1;
                }
                .cta-button {
                    display: inline-block;
                    background-color: #6B46C1;
                    color: white;
                    text-decoration: none;
                    padding: 14px 32px;
                    border-radius: 8px;
                    font-weight: 600;
                    text-align: center;
                    margin: 20px 0;
                    transition: background-color 0.2s;
                }
                .cta-button:hover {
                    background-color: #553C9A;
                }
                .footer {
                    margin-top: 30px;
                    padding-top: 20px;
                    border-top: 1px solid #E2E8F0;
                    font-size: 14px;
                    color: #718096;
                    text-align: center;
                }
                .expiry-notice {
                    background-color: #FEF5E7;
                    border-left: 4px solid #F59E0B;
                    padding: 12px;
                    margin: 20px 0;
                    border-radius: 4px;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>💍 Wedding Planning Invitation</h1>
                    <p>You've been invited to collaborate!</p>
                </div>

                <p>Hi there!</p>

                <p><strong>\(inviterName)</strong> has invited you to collaborate on <strong>\(coupleName)'s wedding planning</strong> using I Do Blueprint.</p>

                <div class="invitation-details">
                    <p><strong>Your Role:</strong> \(role)</p>
                    <p><strong>Couple:</strong> \(coupleName)</p>
                    <p><strong>Invited By:</strong> \(inviterName)</p>
                </div>

                <center>
                    <a href="\(invitationURL)" class="cta-button">Accept Invitation</a>
                </center>

                <div class="expiry-notice">
                    ⏰ <strong>Note:</strong> This invitation expires \(expiryDescription).
                </div>

                <p>I Do Blueprint is a comprehensive wedding planning app that helps couples organize every detail of their special day. As a collaborator, you'll be able to:</p>

                <ul>
                    <li>View and manage wedding tasks</li>
                    <li>Access the guest list and RSVPs</li>
                    <li>Track budget and expenses</li>
                    <li>Share documents and inspiration</li>
                    <li>Coordinate with other collaborators</li>
                </ul>

                <p>If you don't have the I Do Blueprint app installed, clicking the button above will guide you to download it.</p>

                <div class="footer">
                    <p>If you weren't expecting this invitation, you can safely ignore this email.</p>
                    <p style="margin-top: 10px;">© 2025 I Do Blueprint. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
    }

    // MARK: - Helpers

    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Data Models

struct ResendEmailPayload: Encodable {
    let from: String
    let to: [String]
    let subject: String
    let html: String
}

struct ResendEmailResponse: Decodable {
    let id: String
}

// MARK: - Errors

enum EmailError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case invalidResponse
    case badRequest(message: String)
    case unauthorized
    case rateLimitExceeded
    case sendFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Email service is not available. Please try again later."
        case .invalidURL:
            return "Invalid email service URL"
        case .invalidResponse:
            return "Invalid response from email service"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized:
            return "Email service API key is invalid or expired. Please check your API key in Settings."
        case .rateLimitExceeded:
            return "Email rate limit exceeded. Please try again later."
        case .sendFailed(let error):
            return "Failed to send email: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .apiKeyMissing:
            return "This feature uses a shared email service. Please try again later."
        case .unauthorized:
            return "If you're using a custom Resend API key, please verify it in Settings → API Keys."
        case .rateLimitExceeded:
            return "You've reached the daily email sending limit. Please try again tomorrow or upgrade your Resend plan."
        case .badRequest:
            return "Please check that the email address is valid and try again."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}
