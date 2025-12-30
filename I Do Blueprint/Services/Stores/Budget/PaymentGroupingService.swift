//
//  PaymentGroupingService.swift
//  I Do Blueprint
//
//  Extracted from PaymentScheduleStore
//  Handles payment grouping strategies and hierarchical organization
//

import Foundation

/// Service for grouping payment schedules by different strategies
actor PaymentGroupingService {
    
    private let logger = AppLogger.database
    
    // MARK: - Public Methods
    
    /// Group payments by their original payment_plan_id
    func groupByPlanId(_ payments: [PaymentSchedule]) async -> [PaymentPlanSummary] {
        let grouped = Dictionary(grouping: payments) { $0.paymentPlanId }
        
        var summaries: [PaymentPlanSummary] = []
        
        for (planId, paymentsGroup) in grouped {
            guard let planId = planId else { continue }
            
            let sortedPayments = paymentsGroup.sorted { $0.paymentDate < $1.paymentDate }
            guard let firstPayment = sortedPayments.first else { continue }
            
            let summary = createPaymentPlanSummary(
                from: sortedPayments,
                planId: planId,
                expenseId: firstPayment.expenseId ?? planId
            )
            
            summaries.append(summary)
        }
        
        return sortSummariesByNextPayment(summaries)
    }
    
    /// Group all payments for the same expense together
    func groupByExpense(_ payments: [PaymentSchedule]) async -> [PaymentPlanSummary] {
        let grouped = Dictionary(grouping: payments) { $0.expenseId }
        
        var summaries: [PaymentPlanSummary] = []
        
        for (expenseId, paymentsGroup) in grouped {
            guard let expenseId = expenseId else { continue }
            
            let sortedPayments = paymentsGroup.sorted { $0.paymentDate < $1.paymentDate }
            guard sortedPayments.first != nil else { continue }
            
            let summary = createPaymentPlanSummary(
                from: sortedPayments,
                planId: expenseId,
                expenseId: expenseId
            )
            
            summaries.append(summary)
        }
        
        return sortSummariesByNextPayment(summaries)
    }
    
    /// Group all payments for the same vendor together
    func groupByVendor(_ payments: [PaymentSchedule]) async -> [PaymentPlanSummary] {
        let grouped = Dictionary(grouping: payments) { $0.vendorId }
        
        var summaries: [PaymentPlanSummary] = []
        
        for (vendorId, paymentsGroup) in grouped {
            guard let vendorId = vendorId else { continue }
            
            let sortedPayments = paymentsGroup.sorted { $0.paymentDate < $1.paymentDate }
            guard let firstPayment = sortedPayments.first else { continue }
            
            let syntheticPlanId = firstPayment.expenseId ?? UUID()
            
            let summary = createPaymentPlanSummary(
                from: sortedPayments,
                planId: syntheticPlanId,
                expenseId: syntheticPlanId
            )
            
            summaries.append(summary)
        }
        
        return summaries.sorted { $0.vendor < $1.vendor }
    }
    
    /// Group payments hierarchically by expense
    func groupHierarchicallyByExpense(
        _ payments: [PaymentSchedule],
        expenses: [Expense]
    ) async -> [PaymentPlanGroup] {
        let groupedByExpense = Dictionary(grouping: payments) { $0.expenseId }
        
        var groups: [PaymentPlanGroup] = []
        
        for (expenseId, expensePayments) in groupedByExpense {
            guard let expenseId = expenseId else { continue }
            
            let groupedByPlan = Dictionary(grouping: expensePayments) { $0.paymentPlanId }
            var plansForExpense: [PaymentPlanSummary] = []
            
            for (planId, planPayments) in groupedByPlan {
                guard let planId = planId else { continue }
                
                let sortedPayments = planPayments.sorted { $0.paymentDate < $1.paymentDate }
                guard sortedPayments.first != nil else { continue }
                
                let summary = createPaymentPlanSummary(
                    from: sortedPayments,
                    planId: planId,
                    expenseId: expenseId
                )
                
                plansForExpense.append(summary)
            }
            
            plansForExpense = sortSummariesByNextPayment(plansForExpense)
            
            guard let firstPayment = expensePayments.first else { continue }
            let expenseName = expenses.first(where: { $0.id == expenseId })?.expenseName ?? firstPayment.vendor
            
            let group = PaymentPlanGroup(
                id: expenseId,
                groupName: expenseName,
                groupType: .expense(expenseId: expenseId),
                plans: plansForExpense
            )
            
            groups.append(group)
        }
        
        return groups.sorted { $0.groupName < $1.groupName }
    }
    
    /// Group payments hierarchically by vendor
    func groupHierarchicallyByVendor(_ payments: [PaymentSchedule]) async -> [PaymentPlanGroup] {
        let groupedByVendor = Dictionary(grouping: payments) { $0.vendorId }
        
        var groups: [PaymentPlanGroup] = []
        
        for (vendorId, vendorPayments) in groupedByVendor {
            guard let vendorId = vendorId else { continue }
            
            let groupedByPlan = Dictionary(grouping: vendorPayments) { $0.paymentPlanId }
            var plansForVendor: [PaymentPlanSummary] = []
            
            for (planId, planPayments) in groupedByPlan {
                guard let planId = planId else { continue }
                
                let sortedPayments = planPayments.sorted { $0.paymentDate < $1.paymentDate }
                guard let firstPayment = sortedPayments.first else { continue }
                
                let expenseId = firstPayment.expenseId ?? UUID()
                
                let summary = createPaymentPlanSummary(
                    from: sortedPayments,
                    planId: planId,
                    expenseId: expenseId
                )
                
                plansForVendor.append(summary)
            }
            
            plansForVendor = sortSummariesByNextPayment(plansForVendor)
            
            guard let firstPayment = vendorPayments.first else { continue }
            let vendorName = firstPayment.vendor
            
            let group = PaymentPlanGroup(
                id: UUID(),
                groupName: vendorName,
                groupType: .vendor(vendorId: vendorId),
                plans: plansForVendor
            )
            
            groups.append(group)
        }
        
        return groups.sorted { $0.groupName < $1.groupName }
    }
    
    // MARK: - Private Helpers
    
    /// Sort summaries by next payment date
    private func sortSummariesByNextPayment(_ summaries: [PaymentPlanSummary]) -> [PaymentPlanSummary] {
        summaries.sorted { lhs, rhs in
            if let lhsNext = lhs.nextPaymentDate, let rhsNext = rhs.nextPaymentDate {
                return lhsNext < rhsNext
            } else if lhs.nextPaymentDate != nil {
                return true
            } else if rhs.nextPaymentDate != nil {
                return false
            } else {
                return lhs.vendor < rhs.vendor
            }
        }
    }
    
    /// Create a PaymentPlanSummary from a list of payments
    private func createPaymentPlanSummary(
        from payments: [PaymentSchedule],
        planId: UUID,
        expenseId: UUID
    ) -> PaymentPlanSummary {
        let totalAmount = payments.reduce(0) { $0 + $1.paymentAmount }
        let amountPaid = payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
        let amountRemaining = totalAmount - amountPaid
        let percentPaid = totalAmount > 0 ? (amountPaid / totalAmount) * 100 : 0
        
        let paymentsCompleted = Int64(payments.filter { $0.paid }.count)
        let paymentsRemaining = Int64(payments.count) - paymentsCompleted
        
        let allPaid = payments.allSatisfy { $0.paid }
        let anyPaid = payments.contains { $0.paid }
        
        let deposits = payments.filter { $0.isDeposit }
        let depositAmount = deposits.reduce(0) { $0 + $1.paymentAmount }
        let depositCount = Int64(deposits.count)
        
        let nextPayment = payments.first { !$0.paid && $0.paymentDate >= Date() }
        let nextPaymentDate = nextPayment?.paymentDate
        let nextPaymentAmount = nextPayment?.paymentAmount
        
        var daysUntilNextPayment: Int?
        if let nextDate = nextPaymentDate {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: Date(), to: nextDate).day
            daysUntilNextPayment = days
        }
        
        let overduePayments = payments.filter { !$0.paid && $0.paymentDate < Date() }
        let overdueCount = Int64(overduePayments.count)
        let overdueAmount = overduePayments.reduce(0) { $0 + $1.paymentAmount }
        
        let planStatus: PaymentPlanSummary.PlanStatus
        if allPaid {
            planStatus = .completed
        } else if overdueCount > 0 {
            planStatus = .overdue
        } else if anyPaid {
            planStatus = .inProgress
        } else {
            planStatus = .pending
        }
        
        let planType = PaymentPlanTypeAnalyzer.determinePlanType(for: payments)
        
        guard let firstPayment = payments.first else {
            fatalError("Cannot create summary from empty payments array")
        }
        
        let notes = payments.compactMap { $0.notes }.filter { !$0.isEmpty }
        let combinedNotes = notes.isEmpty ? nil : notes.joined(separator: " | ")
        
        return PaymentPlanSummary(
            paymentPlanId: planId,
            expenseId: expenseId,
            coupleId: firstPayment.coupleId,
            vendor: firstPayment.vendor,
            vendorId: firstPayment.vendorId ?? 0,
            vendorType: firstPayment.vendorType,
            paymentType: planType.rawValue,
            paymentPlanType: planType.rawValue,
            planTypeDisplay: planType.displayName,
            totalPayments: payments.count,
            firstPaymentDate: firstPayment.paymentDate,
            lastPaymentDate: payments.last!.paymentDate,
            depositDate: deposits.first?.paymentDate,
            totalAmount: totalAmount,
            amountPaid: amountPaid,
            amountRemaining: amountRemaining,
            depositAmount: depositAmount,
            percentPaid: percentPaid,
            actualPaymentCount: Int64(payments.count),
            paymentsCompleted: paymentsCompleted,
            paymentsRemaining: paymentsRemaining,
            depositCount: depositCount,
            allPaid: allPaid,
            anyPaid: anyPaid,
            hasDeposit: !deposits.isEmpty,
            hasRetainer: payments.contains { $0.isRetainer },
            planStatus: planStatus,
            nextPaymentDate: nextPaymentDate,
            nextPaymentAmount: nextPaymentAmount,
            daysUntilNextPayment: daysUntilNextPayment,
            overdueCount: overdueCount,
            overdueAmount: overdueAmount,
            combinedNotes: combinedNotes,
            planCreatedAt: firstPayment.createdAt,
            planUpdatedAt: payments.compactMap { $0.updatedAt ?? $0.createdAt }.max()
        )
    }
}
