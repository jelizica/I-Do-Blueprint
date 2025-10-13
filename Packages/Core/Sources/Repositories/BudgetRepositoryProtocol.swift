import Foundation

/// Protocol defining budget data operations
public protocol BudgetRepositoryProtocol: Sendable {
    // MARK: - Budget Summary
    func fetchBudgetSummary() async throws -> BudgetSummary?
    func updateBudgetSummary(_ summary: BudgetSummary) async throws -> BudgetSummary

    // MARK: - Categories
    func fetchCategories() async throws -> [BudgetCategory]
    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory
    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory
    func deleteCategory(id: UUID) async throws

    // MARK: - Expenses
    func fetchExpenses(categoryId: UUID?) async throws -> [Expense]
    func createExpense(_ expense: Expense) async throws -> Expense
    func updateExpense(_ expense: Expense) async throws -> Expense
    func deleteExpense(id: UUID) async throws

    // MARK: - Payment Schedules
    func fetchPaymentSchedules() async throws -> [PaymentSchedule]
    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule
    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule
    func deletePaymentSchedule(id: UUID) async throws

    // MARK: - Tax Rates
    func fetchTaxRates() async throws -> [TaxRate]

    // MARK: - Affordability Scenarios
    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario]
    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario
    func deleteAffordabilityScenario(id: UUID) async throws

    // MARK: - Affordability Contributions
    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem]
    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem
    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws

    // MARK: - Cache Management
    func invalidateCache()
}

// MARK: - Supporting Types
public struct BudgetSummary: Codable, Sendable, Identifiable {
    public let id: UUID
    public let totalBudget: Double
    public let allocatedBudget: Double
    public let spentAmount: Double
    public let remainingBudget: Double
    public let categoryCount: Int
    public let expenseCount: Int
    public let lastUpdated: Date

    public init(
        id: UUID = UUID(),
        totalBudget: Double,
        allocatedBudget: Double,
        spentAmount: Double,
        remainingBudget: Double,
        categoryCount: Int,
        expenseCount: Int,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.totalBudget = totalBudget
        self.allocatedBudget = allocatedBudget
        self.spentAmount = spentAmount
        self.remainingBudget = remainingBudget
        self.categoryCount = categoryCount
        self.expenseCount = expenseCount
        self.lastUpdated = lastUpdated
    }
}

public struct BudgetCategory: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let allocatedAmount: Double
    public let spentAmount: Double
    public let color: String?
    public let icon: String?
    public let sortOrder: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        allocatedAmount: Double,
        spentAmount: Double = 0,
        color: String? = nil,
        icon: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.spentAmount = spentAmount
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Expense: Codable, Sendable, Identifiable {
    public let id: UUID
    public let categoryId: UUID
    public let vendorId: UUID?
    public let description: String
    public let amount: Double
    public let paidAmount: Double
    public let dueDate: Date?
    public let paidDate: Date?
    public let notes: String?
    public let status: ExpenseStatus
    public let createdAt: Date
    public let updatedAt: Date

    public enum ExpenseStatus: String, Codable, Sendable {
        case pending
        case paid
        case overdue
        case cancelled
    }

    public init(
        id: UUID = UUID(),
        categoryId: UUID,
        vendorId: UUID? = nil,
        description: String,
        amount: Double,
        paidAmount: Double = 0,
        dueDate: Date? = nil,
        paidDate: Date? = nil,
        notes: String? = nil,
        status: ExpenseStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.categoryId = categoryId
        self.vendorId = vendorId
        self.description = description
        self.amount = amount
        self.paidAmount = paidAmount
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct PaymentSchedule: Codable, Sendable, Identifiable {
    public let id: UUID
    public let categoryId: UUID
    public let expenseId: UUID?
    public let amount: Double
    public let dueDate: Date
    public let paidDate: Date?
    public let status: PaymentStatus
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date

    public enum PaymentStatus: String, Codable, Sendable {
        case pending
        case paid
        case overdue
        case cancelled
    }

    public init(
        id: UUID = UUID(),
        categoryId: UUID,
        expenseId: UUID? = nil,
        amount: Double,
        dueDate: Date,
        paidDate: Date? = nil,
        status: PaymentStatus = .pending,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.categoryId = categoryId
        self.expenseId = expenseId
        self.amount = amount
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TaxRate: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let rate: Double
    public let isDefault: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        rate: Double,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.rate = rate
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}

public struct AffordabilityScenario: Codable, Sendable, Identifiable {
    public let id: UUID
    public var scenarioName: String
    public var partner1Monthly: Double
    public var partner2Monthly: Double
    public var calculationStartDate: Date?
    public var isPrimary: Bool
    public let coupleId: UUID
    public var createdAt: Date
    public var updatedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id
        case scenarioName = "scenario_name"
        case partner1Monthly = "partner1_monthly"
        case partner2Monthly = "partner2_monthly"
        case calculationStartDate = "calculation_start_date"
        case isPrimary = "is_primary"
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        scenarioName: String,
        partner1Monthly: Double,
        partner2Monthly: Double,
        calculationStartDate: Date? = nil,
        isPrimary: Bool = false,
        coupleId: UUID,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioName = scenarioName
        self.partner1Monthly = partner1Monthly
        self.partner2Monthly = partner2Monthly
        self.calculationStartDate = calculationStartDate
        self.isPrimary = isPrimary
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ContributionItem: Codable, Sendable, Identifiable {
    public let id: UUID
    public let scenarioId: UUID
    public var contributorName: String
    public var amount: Double
    public var contributionDate: Date
    public var contributionType: ContributionType
    public var notes: String?
    public let coupleId: UUID
    public var createdAt: Date?
    public var updatedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case contributorName = "contributor_name"
        case amount
        case contributionDate = "contribution_date"
        case contributionType = "contribution_type"
        case notes
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        scenarioId: UUID,
        contributorName: String,
        amount: Double,
        contributionDate: Date = Date(),
        contributionType: ContributionType,
        notes: String? = nil,
        coupleId: UUID,
        createdAt: Date? = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.contributorName = contributorName
        self.amount = amount
        self.contributionDate = contributionDate
        self.contributionType = contributionType
        self.notes = notes
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ContributionType: String, Codable, Sendable, CaseIterable {
    case gift = "gift"
    case external = "external_contribution"

    public var displayName: String {
        switch self {
        case .gift: return "Gift"
        case .external: return "External"
        }
    }
}
