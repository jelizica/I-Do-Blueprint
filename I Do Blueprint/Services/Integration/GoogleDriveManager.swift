import Foundation
import GoogleAPIClientForREST_Drive
import GTMAppAuth

@MainActor
class GoogleDriveManager {
    private let authManager: GoogleAuthManager
    private var driveService: GTLRDriveService?
    private let logger = AppLogger.general

    init(authManager: GoogleAuthManager) {
        self.authManager = authManager
        setupDriveService()
    }

    private func setupDriveService() {
        let service = GTLRDriveService()
        service.shouldFetchNextPages = true
        service.isRetryEnabled = true
        driveService = service
    }

    // MARK: - Upload File

    func uploadFile(fileURL: URL, fileName: String? = nil, mimeType: String) async throws -> String {
        guard let driveService else {
            throw GoogleDriveError.serviceNotInitialized
        }

        // Get authorizer from auth manager
        driveService.authorizer = try authManager.getAuthorizer()

        // Read file data
        let fileData = try Data(contentsOf: fileURL)

        // Create file metadata
        let file = GTLRDrive_File()
        file.name = fileName ?? fileURL.lastPathComponent

        // Create upload parameters
        let uploadParameters = GTLRUploadParameters(data: fileData, mimeType: mimeType)

        // Create query
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        query.fields = "id, name, webViewLink, webContentLink"

        // Execute upload
        let uploadedFile: GTLRDrive_File = try await withCheckedThrowingContinuation { continuation in
            driveService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let file = result as? GTLRDrive_File {
                    continuation.resume(returning: file)
                } else {
                    continuation.resume(throwing: GoogleDriveError.uploadFailed)
                }
            }
        }

        logger.info("File uploaded to Google Drive: \(uploadedFile.name ?? "Unknown")")
        logger.info("Web View Link: \(uploadedFile.webViewLink ?? "N/A")")

        return uploadedFile.identifier ?? ""
    }

    // MARK: - Upload JSON

    func uploadJSON(data: Data, fileName: String) async throws -> String {
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        return try await uploadFile(fileURL: tempURL, fileName: fileName, mimeType: "application/json")
    }

    // MARK: - Upload CSV

    func uploadCSV(data: Data, fileName: String) async throws -> String {
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        return try await uploadFile(fileURL: tempURL, fileName: fileName, mimeType: "text/csv")
    }

    // MARK: - List Files

    func listFiles(limit: Int = 10) async throws -> [GTLRDrive_File] {
        guard let driveService else {
            throw GoogleDriveError.serviceNotInitialized
        }

        driveService.authorizer = try authManager.getAuthorizer()

        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = limit
        query.fields = "files(id, name, mimeType, createdTime, webViewLink)"

        let result: GTLRDrive_FileList = try await withCheckedThrowingContinuation { continuation in
            driveService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let fileList = result as? GTLRDrive_FileList {
                    continuation.resume(returning: fileList)
                } else {
                    continuation.resume(throwing: GoogleDriveError.listFailed)
                }
            }
        }

        return result.files ?? []
    }
}

// MARK: - Errors

enum GoogleDriveError: LocalizedError {
    case serviceNotInitialized
    case uploadFailed
    case listFailed

    var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            "Google Drive service not initialized"
        case .uploadFailed:
            "Failed to upload file to Google Drive"
        case .listFailed:
            "Failed to list files from Google Drive"
        }
    }
}
