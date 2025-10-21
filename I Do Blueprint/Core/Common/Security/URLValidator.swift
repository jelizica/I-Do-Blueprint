//
//  URLValidator.swift
//  I Do Blueprint
//
//  Validates URLs for security before network requests to prevent SSRF and protocol attacks
//

import Foundation

/// Validates URLs for security before network requests
struct URLValidator {
    
    // MARK: - Allowed Schemes
    
    /// Schemes that are allowed for network requests
    private static let allowedSchemes: Set<String> = ["https", "http"]
    
    /// Schemes that are explicitly blocked for security reasons
    private static let blockedSchemes: Set<String> = [
        "file", "ftp", "sftp", "ssh", "telnet", "gopher", "ldap", "dict",
        "data", "javascript", "vbscript", "about"
    ]
    
    // MARK: - Blocked Hosts (SSRF Prevention)
    
    /// Hosts that are blocked to prevent SSRF attacks
    private static let blockedHosts: Set<String> = [
        // Localhost variations
        "localhost", "127.0.0.1", "::1", "0.0.0.0",
        
        // Metadata services (Cloud)
        "169.254.169.254",  // AWS/Azure/GCP metadata service
        "metadata.google.internal",
        "metadata",
        
        // Link-local addresses
        "169.254.0.0",
        
        // Broadcast addresses
        "255.255.255.255"
    ]
    
    /// Private IP range prefixes that should be blocked
    private static let privateIPPrefixes: [String] = [
        "192.168.",  // Private network
        "10.",       // Private network
        "172.16.",   // Private network (172.16.0.0 - 172.31.255.255)
        "172.17.", "172.18.", "172.19.",
        "172.20.", "172.21.", "172.22.", "172.23.",
        "172.24.", "172.25.", "172.26.", "172.27.",
        "172.28.", "172.29.", "172.30.", "172.31."
    ]
    
    // MARK: - Validation
    
    /// Validate URL for security before use
    /// - Parameter url: The URL to validate
    /// - Throws: URLValidationError if the URL is not safe to use
    static func validate(_ url: URL) throws {
        // 1. Check scheme
        guard let scheme = url.scheme?.lowercased() else {
            throw URLValidationError.missingScheme
        }
        
        // Check for blocked schemes first
        if blockedSchemes.contains(scheme) {
            throw URLValidationError.blockedScheme(scheme)
        }
        
        // Check if scheme is in allowed list
        guard allowedSchemes.contains(scheme) else {
            throw URLValidationError.unsupportedScheme(scheme)
        }
        
        // 2. Check host
        guard let host = url.host?.lowercased() else {
            throw URLValidationError.missingHost
        }
        
        // Block dangerous hosts
        if blockedHosts.contains(host) {
            throw URLValidationError.blockedHost(host)
        }
        
        // Block private IP ranges
        for prefix in privateIPPrefixes {
            if host.starts(with: prefix) {
                throw URLValidationError.privateIPRange(host)
            }
        }
        
        // 3. Check for suspicious patterns
        
        // User info in URL (e.g., http://user:pass@example.com)
        if url.user != nil || url.password != nil {
            throw URLValidationError.suspiciousPattern("user credentials in URL")
        }
        
        // Check for @ symbol in host (potential URL confusion attack)
        if host.contains("@") {
            throw URLValidationError.suspiciousPattern("@ symbol in host")
        }
        
        // Check for multiple slashes (potential path traversal)
        if url.absoluteString.contains("//") && !url.absoluteString.hasPrefix("\(scheme)://") {
            throw URLValidationError.suspiciousPattern("multiple slashes")
        }
        
        // 4. Port validation (optional - restrict to standard ports)
        if let port = url.port {
            let allowedPorts: Set<Int> = [80, 443, 8080, 8443]
            guard allowedPorts.contains(port) else {
                throw URLValidationError.blockedPort(port)
            }
        }
        
        // 5. Check for encoded characters that might bypass filters
        let urlString = url.absoluteString
        if urlString.contains("%00") {  // Null byte
            throw URLValidationError.suspiciousPattern("null byte encoding")
        }
        
        // Check for double encoding attempts
        if urlString.contains("%25") {  // Encoded %
            throw URLValidationError.suspiciousPattern("double encoding detected")
        }
    }
    
    /// Validate URL string and return validated URL
    /// - Parameter urlString: The URL string to validate
    /// - Returns: Validated URL
    /// - Throws: URLValidationError if the URL is not safe to use
    static func validateString(_ urlString: String) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw URLValidationError.invalidURLString(urlString)
        }
        try validate(url)
        return url
    }
    
    /// Check if a URL is safe without throwing
    /// - Parameter url: The URL to check
    /// - Returns: true if the URL is safe, false otherwise
    static func isSafe(_ url: URL) -> Bool {
        do {
            try validate(url)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Validation Errors

/// Errors that can occur during URL validation
enum URLValidationError: LocalizedError {
    case missingScheme
    case missingHost
    case blockedScheme(String)
    case unsupportedScheme(String)
    case blockedHost(String)
    case privateIPRange(String)
    case blockedPort(Int)
    case suspiciousPattern(String)
    case invalidURLString(String)
    
    var errorDescription: String? {
        switch self {
        case .missingScheme:
            return "URL missing protocol scheme"
        case .missingHost:
            return "URL missing host"
        case .blockedScheme(let scheme):
            return "Blocked protocol: \(scheme)"
        case .unsupportedScheme(let scheme):
            return "Unsupported protocol: \(scheme). Only HTTP and HTTPS are allowed."
        case .blockedHost(let host):
            return "Blocked host: \(host)"
        case .privateIPRange(let ip):
            return "Private IP address not allowed: \(ip)"
        case .blockedPort(let port):
            return "Port not allowed: \(port). Only ports 80, 443, 8080, and 8443 are allowed."
        case .suspiciousPattern(let pattern):
            return "Suspicious URL pattern detected: \(pattern)"
        case .invalidURLString(let string):
            return "Invalid URL string: \(string)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedScheme, .blockedScheme:
            return "Please use HTTPS or HTTP URLs only."
        case .blockedHost, .privateIPRange:
            return "This URL points to a restricted network location."
        case .blockedPort:
            return "Please use standard web ports (80, 443, 8080, or 8443)."
        case .suspiciousPattern:
            return "This URL contains potentially dangerous patterns."
        case .invalidURLString:
            return "Please provide a valid URL."
        default:
            return "Please check the URL and try again."
        }
    }
}

// MARK: - Convenience Extensions

extension URL {
    /// Check if this URL is safe to use
    var isSafe: Bool {
        URLValidator.isSafe(self)
    }
    
    /// Validate this URL for security
    /// - Throws: URLValidationError if the URL is not safe
    func validateSecurity() throws {
        try URLValidator.validate(self)
    }
}
