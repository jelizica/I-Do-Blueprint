//
//  MoneyReceivedChartSection.swift
//  I Do Blueprint
//
//  Chart visualization for gifts by type
//

import Charts
import SwiftUI

struct MoneyReceivedChartSection: View {
    let giftTypeData: [GiftTypeData]
    let totalReceived: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gifts by Type")
                .font(.headline)
                .padding(.horizontal)
            
            // Donut chart
            chartView
            
            // Legend
            legendView
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Subviews
    
    private var chartView: some View {
        Chart {
            ForEach(giftTypeData, id: \.type) { data in
                SectorMark(
                    angle: .value("Amount", data.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(data.color)
                .cornerRadius(4)
            }
        }
        .frame(height: 200)
        .chartOverlay { _ in
            GeometryReader { geometry in
                VStack {
                    Text("$\(totalReceived, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .position(
                    x: geometry.frame(in: .local).midX,
                    y: geometry.frame(in: .local).midY
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var legendView: some View {
        HStack {
            ForEach(giftTypeData, id: \.type) { data in
                HStack(spacing: 4) {
                    Circle()
                        .fill(data.color)
                        .frame(width: 8, height: 8)
                    Text(data.type.rawValue)
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Data Models

struct GiftTypeData {
    let type: GiftType
    let amount: Double
    let count: Int
    let color: Color
}

// MARK: - Preview

#Preview {
    MoneyReceivedChartSection(
        giftTypeData: [
            GiftTypeData(type: .cash, amount: 2000, count: 5, color: AppColors.Budget.income),
            GiftTypeData(type: .check, amount: 1500, count: 3, color: AppColors.Budget.allocated),
            GiftTypeData(type: .gift, amount: 1000, count: 2, color: .purple),
            GiftTypeData(type: .giftCard, amount: 500, count: 2, color: AppColors.Budget.pending)
        ],
        totalReceived: 5000
    )
    .frame(width: 600)
}
