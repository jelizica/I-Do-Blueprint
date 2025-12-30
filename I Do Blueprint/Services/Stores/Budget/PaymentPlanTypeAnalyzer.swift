//
//  PaymentPlanTypeAnalyzer.swift
//  I Do Blueprint
//
//  Extracted from PaymentScheduleStore
//  Analyzes payment patterns to determine plan type
//

import Foundation

/// Utility for analyzing payment patterns and determining plan types
enum PaymentPlanTypeAnalyzer {
    
    /// Determine plan type from payment pattern
    static func determinePlanType(for payments: [PaymentSchedule]) -> PaymentPlanType {
        if payments.count == 1 {
            return .individual
        }
        
        // Check if all payments have same amount (excluding deposits)
        let nonDepositPayments = payments.filter { !$0.isDeposit }
        
        guard !nonDepositPayments.isEmpty else {
            return .installment
        }
        
        let amounts = Set(nonDepositPayments.map { $0.paymentAmount })
        
        if amounts.count == 1 {
            // Check if monthly intervals
            let sortedDates = nonDepositPayments.map { $0.paymentDate }.sorted()
            var isMonthly = true
            
            for i in 1..<sortedDates.count {
                let interval = Calendar.current.dateComponents([.month], from: sortedDates[i-1], to: sortedDates[i]).month ?? 0
                if interval != 1 {
                    isMonthly = false
                    break
                }
            }
            
            return isMonthly ? .simpleRecurring : .intervalRecurring
        } else {
            return .installment
        }
    }
}
