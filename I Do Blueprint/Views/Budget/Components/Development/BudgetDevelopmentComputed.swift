//
//  BudgetDevelopmentComputed.swift
//  I Do Blueprint
//
//  Computed properties and calculations for budget development
//

import Foundation

// MARK: - Budget Development Calculations

extension BudgetDevelopmentView {

    // MARK: Totals

    var totalWithoutTax: Double {
        budgetItems.reduce(0) { $0 + $1.vendorEstimateWithoutTax }
    }

    var totalTax: Double {
        budgetItems.reduce(0) { $0 + ($1.vendorEstimateWithTax - $1.vendorEstimateWithoutTax) }
    }

    var totalWithTax: Double {
        budgetItems.reduce(0) { $0 + $1.vendorEstimateWithTax }
    }

    // MARK: Breakdowns

    var eventBreakdown: [String: Double] {
        var breakdown: [String: Double] = [:]

        for item in budgetItems {
            let eventIds = item.eventIds ?? []
            let costPerEvent = !eventIds.isEmpty ? item.vendorEstimateWithTax / Double(eventIds.count) : 0

            for eventId in eventIds {
                if let event = budgetStore.weddingEvents.first(where: { $0.id == eventId }) {
                    breakdown[event.eventName, default: 0] += costPerEvent
                }
            }
        }

        return breakdown
    }

    var categoryBreakdown: [String: (total: Double, subcategories: [String: Double])] {
        var breakdown: [String: (total: Double, subcategories: [String: Double])] = [:]

        for item in budgetItems {
            guard !item.category.isEmpty else { continue }

            if breakdown[item.category] == nil {
                breakdown[item.category] = (total: 0, subcategories: [:])
            }

            breakdown[item.category]!.total += item.vendorEstimateWithTax

            if let subcategory = item.subcategory, !subcategory.isEmpty {
                breakdown[item.category]!.subcategories[subcategory, default: 0] += item.vendorEstimateWithTax
            }
        }

        return breakdown
    }

    var personOptions: [String] {
        let p1 = settingsStore.settings.global.partner1Nickname.isEmpty ?
            settingsStore.settings.global.partner1FullName :
            settingsStore.settings.global.partner1Nickname
        let p2 = settingsStore.settings.global.partner2Nickname.isEmpty ?
            settingsStore.settings.global.partner2FullName :
            settingsStore.settings.global.partner2Nickname
        return [p1, p2, "Both"]
    }

    var personBreakdown: [String: Double] {
        var breakdown: [String: Double] = [:]
        for key in personOptions { breakdown[key] = 0 }

        for item in budgetItems {
            breakdown[item.personResponsible ?? "Both", default: 0] += item.vendorEstimateWithTax
        }

        return breakdown
    }

    // MARK: Tax Rate

    var selectedTaxRate: Double {
        guard let selectedId = selectedTaxRateId,
              let taxInfo = budgetStore.taxRates.first(where: { $0.id == selectedId })
        else {
            return (budgetStore.taxRates.first?.taxRate ?? 0.0) * 100
        }
        return taxInfo.taxRate * 100
    }
}
