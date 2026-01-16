//
//  PaymentSchedule+Migration.swift
//  I Do Blueprint
//
//  Extension to handle backward compatibility for payment_type migration
//  Supports legacy values: "single" -> "individual", "custom" -> "interval"/"cyclical"
//

import Foundation

extension PaymentSchedule {
    /// Custom decoder that handles legacy payment_type values
    /// This ensures backward compatibility during the migration period
    /// Note: This extension overrides the synthesized init(from:) to add migration logic
    /// The original init(from:) in Budget.swift will not be used when this extension is present
    
    // Use the shared CodingKeys from PaymentSchedule (now internal in Budget.swift)
    // No need to duplicate the enum definition
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all standard fields
        let id = try container.decode(Int64.self, forKey: .id)
        let coupleId = try container.decode(UUID.self, forKey: .coupleId)
        let vendor = try container.decode(String.self, forKey: .vendor)
        let paymentAmount = try container.decode(Double.self, forKey: .paymentAmount)
        let notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let vendorType = try container.decodeIfPresent(String.self, forKey: .vendorType)
        let paid = try container.decode(Bool.self, forKey: .paid)
        
        // Handle payment_type with backward compatibility
        let paymentTypeString = try container.decodeIfPresent(String.self, forKey: .paymentType)
        let paymentType: String?
        
        if let typeString = paymentTypeString {
            // Check if it's a legacy value
            if PaymentType.isLegacyValue(typeString) {
                // Log the legacy value for monitoring
                AppLogger.database.warning("Legacy payment_type detected: '\(typeString)' for payment \(id)")
                
                // Convert to new canonical value
                if let migratedType = PaymentType(fromDatabaseValue: typeString) {
                    paymentType = migratedType.databaseValue
                    AppLogger.database.info("Migrated payment_type '\(typeString)' -> '\(paymentType!)' for payment \(id)")
                    // Record successful migration
                    PaymentTypeMigrationTracker.shared.recordLegacyValue(typeString, paymentId: id, success: true)
                } else {
                    // Fallback to original value if conversion fails
                    paymentType = typeString
                    AppLogger.database.error("Failed to migrate payment_type '\(typeString)' for payment \(id)")
                    // Record failed migration
                    PaymentTypeMigrationTracker.shared.recordLegacyValue(typeString, paymentId: id, success: false)
                }
            } else {
                // Use the value as-is (already in new format)
                paymentType = typeString
            }
        } else {
            paymentType = nil
        }
        
        // Decode remaining fields
        let customAmount = try container.decodeIfPresent(Double.self, forKey: .customAmount)
        let billingFrequency = try container.decodeIfPresent(String.self, forKey: .billingFrequency)
        let autoRenew = try container.decode(Bool.self, forKey: .autoRenew)
        let reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        let reminderDaysBefore = try container.decodeIfPresent(Int.self, forKey: .reminderDaysBefore)
        let priorityLevel = try container.decodeIfPresent(String.self, forKey: .priorityLevel)
        let expenseId = try container.decodeIfPresent(UUID.self, forKey: .expenseId)
        let vendorId = try container.decodeIfPresent(Int64.self, forKey: .vendorId)
        let isDeposit = try container.decode(Bool.self, forKey: .isDeposit)
        let isRetainer = try container.decode(Bool.self, forKey: .isRetainer)
        let paymentOrder = try container.decodeIfPresent(Int.self, forKey: .paymentOrder)
        let totalPaymentCount = try container.decodeIfPresent(Int.self, forKey: .totalPaymentCount)
        let paymentPlanType = try container.decodeIfPresent(String.self, forKey: .paymentPlanType)
        let paymentPlanId = try container.decodeIfPresent(UUID.self, forKey: .paymentPlanId)
        let segmentIndex = try container.decodeIfPresent(Int.self, forKey: .segmentIndex)

        // Custom date decoding using shared DateDecodingHelpers (refactored from duplicated code)
        let paymentDate = try DateDecodingHelpers.decodeDate(from: container, forKey: .paymentDate)
        let startDate = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .startDate)
        let createdAt = try DateDecodingHelpers.decodeDate(from: container, forKey: .createdAt)
        let updatedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .updatedAt)

        // Decode partial payment tracking fields
        let originalAmount = try container.decodeIfPresent(Double.self, forKey: .originalAmount)
        let amountPaid = try container.decodeIfPresent(Double.self, forKey: .amountPaid) ?? 0
        let carryoverAmount = try container.decodeIfPresent(Double.self, forKey: .carryoverAmount) ?? 0
        let carryoverFromId = try container.decodeIfPresent(Int64.self, forKey: .carryoverFromId)
        let isCarryover = try container.decodeIfPresent(Bool.self, forKey: .isCarryover) ?? false
        let paymentRecordedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .paymentRecordedAt)

        // Initialize self using the memberwise initializer
        self.init(
            id: id,
            coupleId: coupleId,
            vendor: vendor,
            paymentDate: paymentDate,
            paymentAmount: paymentAmount,
            notes: notes,
            vendorType: vendorType,
            paid: paid,
            paymentType: paymentType,
            customAmount: customAmount,
            billingFrequency: billingFrequency,
            autoRenew: autoRenew,
            startDate: startDate,
            reminderEnabled: reminderEnabled,
            reminderDaysBefore: reminderDaysBefore,
            priorityLevel: priorityLevel,
            expenseId: expenseId,
            vendorId: vendorId,
            isDeposit: isDeposit,
            isRetainer: isRetainer,
            paymentOrder: paymentOrder,
            totalPaymentCount: totalPaymentCount,
            paymentPlanType: paymentPlanType,
            paymentPlanId: paymentPlanId,
            segmentIndex: segmentIndex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            originalAmount: originalAmount,
            amountPaid: amountPaid,
            carryoverAmount: carryoverAmount,
            carryoverFromId: carryoverFromId,
            isCarryover: isCarryover,
            paymentRecordedAt: paymentRecordedAt
        )
    }
    
        
    /// Check if this payment schedule has a legacy payment_type that needs migration
    var hasLegacyPaymentType: Bool {
        guard let type = paymentType else { return false }
        return PaymentType.isLegacyValue(type)
    }
    
    /// Get the migrated payment_type value (if applicable)
    var migratedPaymentType: String? {
        guard let type = paymentType else { return nil }
        
        if PaymentType.isLegacyValue(type) {
            return PaymentType(fromDatabaseValue: type)?.databaseValue
        }
        
        return type
    }
}

// MARK: - Migration Helper

/// Helper class to track and report payment type migration status
class PaymentTypeMigrationTracker {
    static let shared = PaymentTypeMigrationTracker()
    
    // Shared mutable state
    private var legacyValuesEncountered: Set<String> = []
    private var successfulMigrationCount: [String: Int] = [:]
    private var failedMigrationCount: [String: Int] = [:]
    private let logger = AppLogger.database
    
    // Synchronization queue to protect shared state
    // Using a serial queue ensures all reads/writes are executed in order without data races.
    private let syncQueue = DispatchQueue(label: "com.ido.blueprint.paymentTypeMigrationTracker")
    
    private init() {}
    
    /// Record a legacy value encounter with migration outcome
    /// - Parameters:
    ///   - value: The legacy payment_type value encountered
    ///   - paymentId: The ID of the payment schedule
    ///   - success: Whether the migration was successful (true) or failed (false)
    func recordLegacyValue(_ value: String, paymentId: Int64, success: Bool) {
        syncQueue.sync {
            legacyValuesEncountered.insert(value)
            if success {
                successfulMigrationCount[value, default: 0] += 1
            } else {
                failedMigrationCount[value, default: 0] += 1
            }
        }
        
        if success {
            logger.info("Legacy payment_type '\(value)' successfully migrated for payment \(paymentId)")
        } else {
            logger.warning("Legacy payment_type '\(value)' failed to migrate for payment \(paymentId)")
        }
    }
    
    /// Get migration statistics
    func getMigrationStats() -> [String: Any] {
        return syncQueue.sync {
            let totalSuccessful = successfulMigrationCount.values.reduce(0, +)
            let totalFailed = failedMigrationCount.values.reduce(0, +)
            
            return [
                "legacyValuesFound": Array(legacyValuesEncountered),
                "successfulMigrationCounts": successfulMigrationCount,
                "failedMigrationCounts": failedMigrationCount,
                "totalSuccessfulMigrations": totalSuccessful,
                "totalFailedMigrations": totalFailed,
                "totalLegacyRecords": totalSuccessful + totalFailed,
                "successRate": totalSuccessful + totalFailed > 0 
                    ? Double(totalSuccessful) / Double(totalSuccessful + totalFailed) * 100 
                    : 0.0
            ]
        }
    }
    
    /// Check if any legacy values have been encountered
    var hasLegacyValues: Bool {
        syncQueue.sync { !legacyValuesEncountered.isEmpty }
    }
    
    /// Check if any migrations have failed
    var hasFailedMigrations: Bool {
        syncQueue.sync { !failedMigrationCount.isEmpty }
    }
    
    /// Reset tracking (useful for testing)
    func reset() {
        syncQueue.sync {
            legacyValuesEncountered.removeAll()
            successfulMigrationCount.removeAll()
            failedMigrationCount.removeAll()
        }
    }
}
