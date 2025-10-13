import AppAuth
import AppKit
import Combine
import Foundation
import GTMAppAuth

@MainActor
class GoogleAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authError: String?

    private var authState: OIDAuthState?
    private let keychainService = "com.jelizica.weddingplanning.google"
    private let keychainAccount = "google-auth-state"

    // Store the redirect HTTP handler
    private var redirectHTTPHandler: OIDRedirectHTTPHandler?

    // OAuth Configuration from secure storage
    private var clientID: String?
    private var clientSecret: String?

    private let credentialsKeychainService = "com.jelizica.weddingplanning.google.credentials"
    private let clientIDKeychainAccount = "google-client-id"
    private let clientSecretKeychainAccount = "google-client-secret"

    // Google API Scopes
    private let scopes = [
        "https://www.googleapis.com/auth/drive.file",
        "https://www.googleapis.com/auth/spreadsheets"
    ]

    private let logger = AppLogger.auth

    init() {
        loadCredentials()
        loadAuthState()
    }

    // MARK: - Load OAuth Credentials from Keychain

    private func loadCredentials() {
        // Load client ID
        clientID = loadCredentialFromKeychain(account: clientIDKeychainAccount)

        // Load client secret
        clientSecret = loadCredentialFromKeychain(account: clientSecretKeychainAccount)

        if clientID != nil, clientSecret != nil {
            logger.info("OAuth credentials loaded successfully from keychain")
        } else {
            logger.error("Failed to load OAuth credentials from keychain")
            authError = "OAuth credentials not found in secure storage. Please configure credentials."
        }
    }

    private func loadCredentialFromKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: credentialsKeychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let credential = String(data: data, encoding: .utf8) {
            return credential
        }

        return nil
    }

    // MARK: - Store OAuth Credentials in Keychain

    func storeCredentials(clientID: String, clientSecret: String) {
        storeCredentialInKeychain(value: clientID, account: clientIDKeychainAccount)
        storeCredentialInKeychain(value: clientSecret, account: clientSecretKeychainAccount)

        // Reload credentials
        loadCredentials()
    }

    private func storeCredentialInKeychain(value: String, account: String) {
        guard let data = value.data(using: .utf8) else {
            logger.error("Failed to encode credential for account: \(account)")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: credentialsKeychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            logger.info("Credential saved to keychain for account: \(account)")
        } else {
            logger.error("Failed to save credential to keychain for account \(account): \(status)")
        }
    }

    // MARK: - Authentication

    func authenticate() async throws {
        guard let clientID,
              let clientSecret else {
            throw GoogleAuthError.credentialsNotFound
        }

        // Configure OAuth endpoints
        guard let issuer = URL(string: "https://accounts.google.com") else {
            throw GoogleAuthError.invalidConfiguration
        }

        // Discover OAuth endpoints
        let configuration: OIDServiceConfiguration
        do {
            configuration = try await withCheckedThrowingContinuation { continuation in
                OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
                    if let config {
                        continuation.resume(returning: config)
                    } else {
                        continuation.resume(throwing: error ?? GoogleAuthError.discoveryFailed)
                    }
                }
            }
        } catch {
            throw GoogleAuthError.discoveryFailed
        }

        // Create a loopback HTTP redirect handler
        let redirectHTTPHandler = OIDRedirectHTTPHandler(successURL: nil)
        self.redirectHTTPHandler = redirectHTTPHandler

        // Start the HTTP handler and get the redirect URL
        let redirectURL = redirectHTTPHandler.startHTTPListener(nil)

        // Create authorization request
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: scopes,
            redirectURL: redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        // Get the main window
        guard let mainWindow = NSApplication.shared.windows.first else {
            redirectHTTPHandler.cancelHTTPListener()
            throw GoogleAuthError.noWindow
        }

        // Present authentication UI using external user agent (browser)
        let authState = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
            OIDAuthState,
            Error
        >) in
            let externalUserAgent = OIDExternalUserAgentMac(presenting: mainWindow)

            let callback: OIDAuthStateAuthorizationCallback = { authState, error in
                // Always clean up the HTTP listener
                redirectHTTPHandler.cancelHTTPListener()

                if let authState {
                    continuation.resume(returning: authState)
                } else {
                    continuation.resume(throwing: error ?? GoogleAuthError.authorizationFailed)
                }
            }

            // Start the authorization flow
            redirectHTTPHandler.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                externalUserAgent: externalUserAgent,
                callback: callback)
        }

        // Clean up
        self.redirectHTTPHandler = nil

        // Save auth state
        self.authState = authState
        isAuthenticated = true
        saveAuthState()

        logger.info("Google authentication successful")
    }

    func signOut() {
        authState = nil
        isAuthenticated = false
        deleteAuthState()
        logger.info("Signed out from Google")
    }

    // MARK: - Access Token

    func getAccessToken() async throws -> String {
        guard let authState else {
            throw GoogleAuthError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            authState.performAction { accessToken, _, error in
                if let accessToken {
                    continuation.resume(returning: accessToken)
                } else {
                    continuation.resume(throwing: error ?? GoogleAuthError.tokenRetrievalFailed)
                }
            }
        }
    }

    func getAuthorizer() throws -> AuthSession {
        guard let authState else {
            throw GoogleAuthError.notAuthenticated
        }
        return AuthSession(authState: authState)
    }

    // MARK: - Keychain Storage

    private func saveAuthState() {
        guard let authState,
              let data = try? NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true) else {
            logger.error("Failed to archive auth state")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            logger.info("Auth state saved to keychain")
        } else {
            logger.error("Failed to save auth state to keychain: \(status)")
        }
    }

    private func loadAuthState() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let authState = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
            self.authState = authState
            isAuthenticated = true
            logger.info("Auth state loaded from keychain")
        } else {
            logger.debug("No saved auth state found")
        }
    }

    private func deleteAuthState() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Errors

enum GoogleAuthError: LocalizedError {
    case credentialsNotFound
    case invalidConfiguration
    case discoveryFailed
    case noWindow
    case authorizationFailed
    case notAuthenticated
    case tokenRetrievalFailed

    var errorDescription: String? {
        switch self {
        case .credentialsNotFound:
            "OAuth credentials file not found. Please check your client_secret JSON file."
        case .invalidConfiguration:
            "Invalid OAuth configuration"
        case .discoveryFailed:
            "Failed to discover OAuth endpoints"
        case .noWindow:
            "No window available for authentication"
        case .authorizationFailed:
            "Authorization failed or was cancelled"
        case .notAuthenticated:
            "Not authenticated. Please sign in first."
        case .tokenRetrievalFailed:
            "Failed to retrieve access token"
        }
    }
}
