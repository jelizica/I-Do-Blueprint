//
//  DocumentModels.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation

// MARK: - Document Model

struct Document: Codable, Equatable, Identifiable {
    let id: UUID
    let coupleId: UUID
    var originalFilename: String
    var storagePath: String
    var fileSize: Int64
    var mimeType: String
    var documentType: DocumentType
    var bucketName: String
    var vendorId: Int?
    var expenseId: UUID?
    var paymentId: Int64?
    var tags: [String]
    var uploadedBy: String
    let uploadedAt: Date
    var updatedAt: Date
    var autoTagStatus: AutoTagStatus
    var autoTagSource: AutoTagSource
    var autoTaggedAt: Date?
    var autoTagError: String?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case originalFilename = "original_filename"
        case storagePath = "storage_path"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case documentType = "document_type"
        case bucketName = "bucket_name"
        case vendorId = "vendor_id"
        case expenseId = "expense_id"
        case paymentId = "payment_id"
        case tags
        case uploadedBy = "uploaded_by"
        case uploadedAt = "uploaded_at"
        case updatedAt = "updated_at"
        case autoTagStatus = "auto_tag_status"
        case autoTagSource = "auto_tag_source"
        case autoTaggedAt = "auto_tagged_at"
        case autoTagError = "auto_tag_error"
    }

    var displayName: String {
        originalFilename
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var isImage: Bool {
        mimeType.starts(with: "image/")
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    var fileExtension: String {
        (originalFilename as NSString).pathExtension.uppercased()
    }
}

// MARK: - Document Type

enum DocumentType: String, Codable, CaseIterable {
    case contract
    case invoice
    case receipt
    case photo
    case other

    var displayName: String {
        switch self {
        case .contract: "Contract"
        case .invoice: "Invoice"
        case .receipt: "Receipt"
        case .photo: "Photo"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .contract: "doc.text.fill"
        case .invoice: "doc.plaintext.fill"
        case .receipt: "receipt.fill"
        case .photo: "photo.fill"
        case .other: "doc.fill"
        }
    }

    var color: String {
        switch self {
        case .contract: "blue"
        case .invoice: "green"
        case .receipt: "orange"
        case .photo: "purple"
        case .other: "gray"
        }
    }
}

// MARK: - Auto Tag Status

enum AutoTagStatus: String, Codable {
    case manual
    case autoPending = "auto_pending"
    case autoComplete = "auto_complete"
    case autoFailed = "auto_failed"
}

// MARK: - Auto Tag Source

enum AutoTagSource: String, Codable {
    case manual
    case ai
    case heuristic
}

// MARK: - Document Bucket

enum DocumentBucket: String, Codable, CaseIterable {
    case vendorProfilePics = "vendor-profile-pics"
    case invoicesAndContracts = "invoices-and-contracts"
    case moodBoardAssets = "mood-board-assets"
    case contracts = "contracts"

    var displayName: String {
        switch self {
        case .vendorProfilePics: "Vendor Profile Pictures"
        case .invoicesAndContracts: "Invoices & Contracts"
        case .moodBoardAssets: "Mood Board Assets"
        case .contracts: "Contracts"
        }
    }

    var iconName: String {
        switch self {
        case .vendorProfilePics: "person.crop.circle"
        case .invoicesAndContracts: "folder.fill"
        case .moodBoardAssets: "paintpalette.fill"
        case .contracts: "doc.text.fill"
        }
    }
}

// MARK: - Document Filters

struct DocumentFilters: Equatable {
    var selectedType: DocumentType?
    var selectedBucket: DocumentBucket?
    var tags: [String]
    var dateRange: DocumentDateRange?
    var vendorId: Int?

    var hasActiveFilters: Bool {
        selectedType != nil || selectedBucket != nil || !tags.isEmpty || dateRange != nil || vendorId != nil
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedType != nil { count += 1 }
        if selectedBucket != nil { count += 1 }
        count += tags.count
        if dateRange != nil { count += 1 }
        if vendorId != nil { count += 1 }
        return count
    }

    mutating func clear() {
        selectedType = nil
        selectedBucket = nil
        tags.removeAll()
        dateRange = nil
        vendorId = nil
    }
}

// MARK: - Document Date Range

enum DocumentDateRange: Equatable, Hashable {
    case last7Days
    case last30Days
    case last90Days
    case thisYear
    case custom(start: Date, end: Date)

    var displayName: String {
        switch self {
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .thisYear: return "This Year"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    var dateInterval: DateInterval {
        let now = Date()
        switch self {
        case .last7Days:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -7, to: now)!, end: now)
        case .last30Days:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -30, to: now)!, end: now)
        case .last90Days:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -90, to: now)!, end: now)
        case .thisYear:
            let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: now))!
            return DateInterval(start: startOfYear, end: now)
        case .custom(let start, let end):
            return DateInterval(start: start, end: end)
        }
    }
}

// MARK: - Document Sort Options

enum DocumentSortOption: String, CaseIterable {
    case uploadedDesc = "uploaded_desc"
    case uploadedAsc = "uploaded_asc"
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case sizeDesc = "size_desc"
    case sizeAsc = "size_asc"
    case typeAsc = "type_asc"

    var displayName: String {
        switch self {
        case .uploadedDesc: "Newest First"
        case .uploadedAsc: "Oldest First"
        case .nameAsc: "Name (A-Z)"
        case .nameDesc: "Name (Z-A)"
        case .sizeDesc: "Size (Largest)"
        case .sizeAsc: "Size (Smallest)"
        case .typeAsc: "Type"
        }
    }
}

// MARK: - File Upload Metadata

struct FileUploadMetadata: Identifiable {
    let id = UUID()
    let localURL: URL
    var fileName: String
    var documentType: DocumentType = .other
    var bucket: DocumentBucket = .invoicesAndContracts
    var vendorId: Int?
    var expenseId: UUID?
    var tags: [String] = []

    // Upload state
    var uploadProgress: Double = 0.0
    var isUploading: Bool = false
    var uploadError: String?
    var isComplete: Bool = false

    var fileSize: Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path),
              let size = attributes[.size] as? NSNumber else {
            return 0
        }
        return size.int64Value
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var mimeType: String {
        let pathExtension = localURL.pathExtension.lowercased()
        switch pathExtension {
        case "pdf": return "application/pdf"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        default: return "application/octet-stream"
        }
    }

    var isImage: Bool {
        mimeType.starts(with: "image/")
    }
}

// MARK: - Document Insert Data

struct DocumentInsertData: Codable {
    var coupleId: UUID
    var originalFilename: String
    var storagePath: String
    var fileSize: Int64
    var mimeType: String
    var documentType: DocumentType
    var bucketName: String
    var vendorId: Int?
    var expenseId: UUID?
    var tags: [String]
    var uploadedBy: String
    var autoTagStatus: AutoTagStatus = .manual
    var autoTagSource: AutoTagSource = .manual

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case originalFilename = "original_filename"
        case storagePath = "storage_path"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case documentType = "document_type"
        case bucketName = "bucket_name"
        case vendorId = "vendor_id"
        case expenseId = "expense_id"
        case tags
        case autoTagStatus = "auto_tag_status"
        case autoTagSource = "auto_tag_source"
        case uploadedBy = "uploaded_by"
    }

    func validate() -> [String] {
        var errors: [String] = []

        if originalFilename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("File name is required")
        }

        if storagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Storage path is required")
        }

        if fileSize <= 0 {
            errors.append("File size must be greater than 0")
        }

        // Max file size: 50MB
        if fileSize > 50 * 1024 * 1024 {
            errors.append("File size must be less than 50MB")
        }

        return errors
    }
}

// MARK: - View Mode

enum DocumentViewMode: String, CaseIterable {
    case grid
    case list

    var iconName: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .list: "list.bullet"
        }
    }

    var displayName: String {
        switch self {
        case .grid: "Grid"
        case .list: "List"
        }
    }
}

// MARK: - Batch Operation

enum BatchOperation {
    case download
    case delete
    case addTag(String)
    case removeTag(String)
    case changeType(DocumentType)

    var displayName: String {
        switch self {
        case .download: "Download"
        case .delete: "Delete"
        case .addTag: "Add Tag"
        case .removeTag: "Remove Tag"
        case .changeType: "Change Type"
        }
    }
}

// MARK: - Search History Item

struct SearchHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let timestamp: Date

    init(query: String) {
        id = UUID()
        self.query = query
        timestamp = Date()
    }
}
