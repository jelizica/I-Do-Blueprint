//
//  ModelBuilders.swift
//  I Do BlueprintTests
//
//  Test model builders for all domain models
//

import Foundation
import SwiftUI
@testable import I_Do_Blueprint

// MARK: - Guest Builders

extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        firstName: String = "John",
        lastName: String = "Doe",
        email: String? = "john.doe@test.com",
        phone: String? = "+1234567890",
        rsvpStatus: RSVPStatus = .pending,
        plusOneAllowed: Bool = false,
        plusOneName: String? = nil,
        plusOneAttending: Bool = false,
        attendingCeremony: Bool = true,
        attendingReception: Bool = true,
        isWeddingParty: Bool = false,
        giftReceived: Bool = false,
        hairDone: Bool = false,
        makeupDone: Bool = false
    ) -> Guest {
        Guest(
            id: id,
            createdAt: Date(),
            updatedAt: Date(),
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            guestGroupId: nil,
            relationshipToCouple: nil,
            invitedBy: nil,
            rsvpStatus: rsvpStatus,
            rsvpDate: nil,
            plusOneAllowed: plusOneAllowed,
            plusOneName: plusOneName,
            plusOneAttending: plusOneAttending,
            attendingCeremony: attendingCeremony,
            attendingReception: attendingReception,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            invitationNumber: nil,
            isWeddingParty: isWeddingParty,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: coupleId,
            mealOption: nil,
            giftReceived: giftReceived,
            notes: nil,
            hairDone: hairDone,
            makeupDone: makeupDone
        )
    }
}

// MARK: - Budget Builders

extension BudgetCategory {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        categoryName: String = "Test Category",
        allocatedAmount: Double = 1000.0,
        spentAmount: Double = 500.0,
        priorityLevel: Int = 2,
        isEssential: Bool = false,
        forecastedAmount: Double = 500.0,
        confidenceLevel: Double = 0.8,
        lockedAllocation: Bool = false
    ) -> BudgetCategory {
        BudgetCategory(
            id: id,
            coupleId: coupleId,
            categoryName: categoryName,
            parentCategoryId: nil,
            allocatedAmount: allocatedAmount,
            spentAmount: spentAmount,
            typicalPercentage: nil,
            priorityLevel: priorityLevel,
            isEssential: isEssential,
            notes: nil,
            forecastedAmount: forecastedAmount,
            confidenceLevel: confidenceLevel,
            lockedAllocation: lockedAllocation,
            description: nil,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

extension Expense {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        budgetCategoryId: UUID = UUID(),
        expenseName: String = "Test Expense",
        amount: Double = 100.0,
        paymentStatus: PaymentStatus = .pending,
        isTestData: Bool = true
    ) -> Expense {
        Expense(
            id: id,
            coupleId: coupleId,
            budgetCategoryId: budgetCategoryId,
            vendorId: nil,
            vendorName: nil,
            expenseName: expenseName,
            amount: amount,
            expenseDate: Date(),
            paymentMethod: nil,
            paymentStatus: paymentStatus,
            receiptUrl: nil,
            invoiceNumber: nil,
            notes: nil,
            approvalStatus: nil,
            approvedBy: nil,
            approvedAt: nil,
            invoiceDocumentUrl: nil,
            isTestData: isTestData,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

extension PaymentSchedule {
    static func makeTest(
        id: Int64 = 1,
        coupleId: UUID = UUID(),
        vendor: String = "Test Vendor",
        paymentDate: Date = Date(),
        paymentAmount: Double = 1000.0,
        notes: String? = nil,
        vendorType: String? = nil,
        paid: Bool = false,
        paymentType: String? = nil,
        customAmount: Double? = nil,
        billingFrequency: String? = nil,
        autoRenew: Bool = false,
        startDate: Date? = nil,
        reminderEnabled: Bool = false,
        reminderDaysBefore: Int? = nil,
        priorityLevel: String? = nil,
        expenseId: UUID? = nil,
        vendorId: Int64? = nil,
        isDeposit: Bool = false,
        isRetainer: Bool = false,
        paymentOrder: Int? = nil,
        totalPaymentCount: Int? = nil,
        paymentPlanType: String? = nil
    ) -> PaymentSchedule {
        PaymentSchedule(
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
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

extension GiftOrOwed {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        title: String = "Test Gift",
        amount: Double = 500.0,
        type: GiftOrOwed.GiftOrOwedType = .giftReceived,
        status: GiftOrOwed.GiftOrOwedStatus = .pending,
        scenarioId: UUID? = nil
    ) -> GiftOrOwed {
        GiftOrOwed(
            id: id,
            coupleId: coupleId,
            title: title,
            amount: amount,
            type: type,
            description: nil,
            fromPerson: nil,
            expectedDate: nil,
            receivedDate: nil,
            status: status,
            scenarioId: scenarioId,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

extension GiftReceived {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        fromPerson: String = "Test Person",
        amount: Double = 500.0,
        dateReceived: Date = Date(),
        giftType: GiftType = .cash,
        isThankYouSent: Bool = false
    ) -> GiftReceived {
        GiftReceived(
            id: id,
            coupleId: coupleId,
            fromPerson: fromPerson,
            amount: amount,
            dateReceived: dateReceived,
            giftType: giftType,
            notes: nil,
            isThankYouSent: isThankYouSent
        )
    }
}

extension MoneyOwed {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        toPerson: String = "Test Person",
        amount: Double = 300.0,
        reason: String = "Test Reason",
        dueDate: Date? = nil,
        priority: OwedPriority = .medium,
        isPaid: Bool = false
    ) -> MoneyOwed {
        MoneyOwed(
            id: id,
            coupleId: coupleId,
            toPerson: toPerson,
            amount: amount,
            reason: reason,
            dueDate: dueDate,
            priority: priority,
            notes: nil,
            isPaid: isPaid
        )
    }
}

extension BudgetItem {
    static func makeTest(
        id: String = UUID().uuidString,
        coupleId: String = UUID().uuidString,
        scenarioId: String = "test-scenario",
        itemName: String = "Test Budget Item",
        vendorEstimateWithoutTax: Double = 1000.0,
        taxRate: Double = 0.08,
        isFolder: Bool = false,
        parentFolderId: String? = nil,
        displayOrder: Int = 0
    ) -> BudgetItem {
        BudgetItem(
            id: id,
            coupleId: coupleId,
            scenarioId: scenarioId,
            itemName: itemName,
            vendorEstimateWithoutTax: vendorEstimateWithoutTax,
            taxRate: taxRate,
            vendorEstimateWithTax: vendorEstimateWithoutTax * (1 + taxRate),
            isFolder: isFolder,
            parentFolderId: parentFolderId,
            displayOrder: displayOrder,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension SavedScenario {
    static func makeTest(
        id: String = UUID().uuidString,
        coupleId: String = UUID().uuidString,
        scenarioName: String = "Test Scenario",
        isPrimary: Bool = false
    ) -> SavedScenario {
        SavedScenario(
            id: id,
            coupleId: coupleId,
            scenarioName: scenarioName,
            isPrimary: isPrimary,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension BudgetOverviewItem {
    static func makeTest(
        id: String = UUID().uuidString,
        coupleId: String = UUID().uuidString,
        scenarioId: String = "test-scenario",
        itemName: String = "Test Overview Item",
        vendorEstimateWithoutTax: Double = 1000.0,
        taxRate: Double = 0.08,
        spentAmount: Double = 500.0,
        isFolder: Bool = false
    ) -> BudgetOverviewItem {
        BudgetOverviewItem(
            id: id,
            coupleId: coupleId,
            scenarioId: scenarioId,
            itemName: itemName,
            vendorEstimateWithoutTax: vendorEstimateWithoutTax,
            taxRate: taxRate,
            vendorEstimateWithTax: vendorEstimateWithoutTax * (1 + taxRate),
            spentAmount: spentAmount,
            isFolder: isFolder,
            parentFolderId: nil,
            displayOrder: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension TaxInfo {
    static func makeTest(
        id: Int64 = 1,
        coupleId: UUID = UUID(),
        taxName: String = "Sales Tax",
        taxRate: Double = 0.08,
        isDefault: Bool = false
    ) -> TaxInfo {
        TaxInfo(
            id: id,
            coupleId: coupleId,
            taxName: taxName,
            taxRate: taxRate,
            isDefault: isDefault,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension WeddingEvent {
    static func makeTest(
        id: String = UUID().uuidString,
        coupleId: UUID = UUID(),
        eventName: String = "Test Event",
        eventDate: Date = Date(),
        eventType: String = "ceremony"
    ) -> WeddingEvent {
        WeddingEvent(
            id: id,
            coupleId: coupleId,
            eventName: eventName,
            eventDate: eventDate,
            eventType: eventType,
            location: nil,
            description: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension AffordabilityScenario {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        scenarioName: String = "Test Affordability",
        totalBudget: Double = 50000.0,
        monthlyIncome: Double = 10000.0,
        monthlyExpenses: Double = 5000.0
    ) -> AffordabilityScenario {
        AffordabilityScenario(
            id: id,
            coupleId: coupleId,
            scenarioName: scenarioName,
            totalBudget: totalBudget,
            monthlyIncome: monthlyIncome,
            monthlyExpenses: monthlyExpenses,
            savingsGoal: nil,
            monthsToWedding: 12,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension ContributionItem {
    static func makeTest(
        id: UUID = UUID(),
        scenarioId: UUID = UUID(),
        coupleId: UUID = UUID(),
        contributorName: String = "Test Contributor",
        amount: Double = 5000.0,
        contributionType: String = "gift"
    ) -> ContributionItem {
        ContributionItem(
            id: id,
            scenarioId: scenarioId,
            coupleId: coupleId,
            contributorName: contributorName,
            amount: amount,
            contributionType: contributionType,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension ExpenseAllocation {
    static func makeTest(
        id: String = UUID().uuidString,
        expenseId: String = UUID().uuidString,
        budgetItemId: String = UUID().uuidString,
        scenarioId: String = "test-scenario",
        allocatedAmount: Double = 500.0
    ) -> ExpenseAllocation {
        ExpenseAllocation(
            id: id,
            expenseId: expenseId,
            budgetItemId: budgetItemId,
            scenarioId: scenarioId,
            allocatedAmount: allocatedAmount,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension FolderTotals {
    static func makeTest(
        withoutTax: Double = 10000.0,
        tax: Double = 800.0,
        withTax: Double = 10800.0
    ) -> FolderTotals {
        FolderTotals(
            withoutTax: withoutTax,
            tax: tax,
            withTax: withTax
        )
    }
}

extension BudgetSummary {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        totalBudget: Double = 50000.0,
        totalSpent: Double = 25000.0,
        totalAllocated: Double = 45000.0
    ) -> BudgetSummary {
        BudgetSummary(
            id: id,
            coupleId: coupleId,
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalAllocated: totalAllocated,
            remainingBudget: totalBudget - totalSpent,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension BudgetDevelopmentScenario {
    static func makeTest(
        id: String = UUID().uuidString,
        coupleId: String = UUID().uuidString,
        scenarioName: String = "Test Development Scenario",
        isPrimary: Bool = false,
        totalEstimate: Double = 50000.0
    ) -> BudgetDevelopmentScenario {
        BudgetDevelopmentScenario(
            id: id,
            coupleId: coupleId,
            scenarioName: scenarioName,
            isPrimary: isPrimary,
            totalEstimate: totalEstimate,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Task Builders

extension WeddingTask {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        taskName: String = "Test Task",
        priority: WeddingTaskPriority = .medium,
        status: TaskStatus = .notStarted,
        dueDate: Date? = nil
    ) -> WeddingTask {
        WeddingTask(
            id: id,
            coupleId: coupleId,
            taskName: taskName,
            description: nil,
            budgetCategoryId: nil,
            priority: priority,
            dueDate: dueDate,
            startDate: nil,
            assignedTo: [],
            vendorId: nil,
            status: status,
            dependsOnTaskId: nil,
            estimatedHours: nil,
            costEstimate: nil,
            notes: nil,
            milestoneId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            subtasks: nil,
            milestone: nil,
            vendor: nil,
            budgetCategory: nil
        )
    }
}

extension Subtask {
    static func makeTest(
        id: UUID = UUID(),
        taskId: UUID = UUID(),
        subtaskName: String = "Test Subtask",
        status: TaskStatus = .notStarted,
        assignedTo: [String] = [],
        notes: String? = nil
    ) -> Subtask {
        Subtask(
            id: id,
            taskId: taskId,
            subtaskName: subtaskName,
            status: status,
            assignedTo: assignedTo,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Timeline Builders

extension TimelineItem {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        title: String = "Test Timeline Item",
        itemType: TimelineItemType = .other,
        itemDate: Date = Date(),
        completed: Bool = false
    ) -> TimelineItem {
        TimelineItem(
            id: id,
            coupleId: coupleId,
            title: title,
            description: nil,
            itemType: itemType,
            itemDate: itemDate,
            endDate: nil,
            completed: completed,
            relatedId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            task: nil,
            milestone: nil,
            vendor: nil,
            payment: nil
        )
    }
}

extension Milestone {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        milestoneName: String = "Test Milestone",
        milestoneDate: Date = Date(),
        completed: Bool = false
    ) -> Milestone {
        Milestone(
            id: id,
            coupleId: coupleId,
            milestoneName: milestoneName,
            description: nil,
            milestoneDate: milestoneDate,
            completed: completed,
            color: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Settings Builders

extension CoupleSettings {
    static func makeTest(
        currency: String = "USD",
        weddingDate: String = "2025-12-31",
        totalBudget: Double = 50000.0
    ) -> CoupleSettings {
        var settings = CoupleSettings.default
        settings.global.currency = currency
        settings.global.weddingDate = weddingDate
        settings.budget.totalBudget = totalBudget
        settings.budget.baseBudget = totalBudget
        return settings
    }
}

// MARK: - Notes Builders

extension Note {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        title: String? = "Test Note",
        content: String = "Test content",
        relatedType: NoteRelatedType? = nil,
        relatedId: String? = nil
    ) -> Note {
        Note(
            id: id,
            coupleId: coupleId,
            title: title,
            content: content,
            relatedType: relatedType,
            relatedId: relatedId,
            createdAt: Date(),
            updatedAt: Date(),
            relatedEntity: nil
        )
    }
}

// MARK: - Document Builders

extension Document {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        originalFilename: String = "test.pdf",
        storagePath: String = "test/path",
        fileSize: Int64 = 1024,
        mimeType: String = "application/pdf",
        documentType: DocumentType = .other,
        bucketName: String = "invoices-and-contracts"
    ) -> Document {
        Document(
            id: id,
            coupleId: coupleId,
            originalFilename: originalFilename,
            storagePath: storagePath,
            fileSize: fileSize,
            mimeType: mimeType,
            documentType: documentType,
            bucketName: bucketName,
            vendorId: nil,
            expenseId: nil,
            paymentId: nil,
            tags: [],
            uploadedBy: "test-user",
            uploadedAt: Date(),
            updatedAt: Date(),
            autoTagStatus: .manual,
            autoTagSource: .manual,
            autoTaggedAt: nil,
            autoTagError: nil
        )
    }
}

// MARK: - Vendor Builders

extension Vendor {
    static func makeTest(
        id: Int64 = 1,
        coupleId: UUID = UUID(),
        vendorName: String = "Test Vendor",
        vendorType: String? = "Photography",
        isBooked: Bool? = false,
        isArchived: Bool = false,
        includeInExport: Bool = true
    ) -> Vendor {
        Vendor(
            id: id,
            createdAt: Date(),
            updatedAt: nil,
            vendorName: vendorName,
            vendorType: vendorType,
            vendorCategoryId: nil,
            contactName: nil,
            phoneNumber: nil,
            email: nil,
            website: nil,
            notes: nil,
            quotedAmount: nil,
            imageUrl: nil,
            isBooked: isBooked,
            dateBooked: nil,
            budgetCategoryId: nil,
            coupleId: coupleId,
            isArchived: isArchived,
            archivedAt: nil,
            includeInExport: includeInExport,
            streetAddress: nil,
            streetAddress2: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            country: nil,
            latitude: nil,
            longitude: nil
        )
    }
}

// MARK: - Visual Planning Builders

extension MoodBoard {
    static func makeTest(
        id: UUID = UUID(),
        tenantId: String = "test-tenant",
        boardName: String = "Test Board",
        styleCategory: StyleCategory = .modern,
        backgroundColor: Color = .white
    ) -> MoodBoard {
        MoodBoard(
            id: id,
            tenantId: tenantId,
            boardName: boardName,
            boardDescription: nil,
            styleCategory: styleCategory,
            colorPaletteId: nil,
            canvasSize: CGSize(width: 800, height: 600),
            backgroundColor: backgroundColor,
            backgroundImage: nil,
            elements: [],
            isTemplate: false,
            isPublic: false,
            tags: [],
            inspirationUrls: [],
            notes: nil
        )
    }
}

extension ColorPalette {
    static func makeTest(
        id: UUID = UUID(),
        name: String = "Test Palette",
        colors: [String] = ["#FF0000", "#00FF00", "#0000FF"],
        isDefault: Bool = false
    ) -> ColorPalette {
        ColorPalette(
            id: id,
            name: name,
            colors: colors,
            description: nil,
            isDefault: isDefault,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension SeatingChart {
    static func makeTest(
        id: UUID = UUID(),
        tenantId: String = "test-tenant",
        chartName: String = "Test Chart",
        isFinalized: Bool = false
    ) -> SeatingChart {
        SeatingChart(
            tenantId: tenantId,
            chartName: chartName,
            eventId: nil,
            venueLayoutType: .round,
            venueConfiguration: VenueConfiguration(),
            chartDescription: nil,
            isFinalized: isFinalized
        )
    }
}
