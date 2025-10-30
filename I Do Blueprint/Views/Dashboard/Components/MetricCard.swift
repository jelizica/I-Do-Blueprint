//
//  MetricCard.swift
//  I Do Blueprint
//
//  Metric card for key statistics
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: Double
    var total: Double?
    let format: MetricFormat
    let icon: String
    let color: Color
    
    enum MetricFormat {
        case percentage
        case fraction
        case number
        case currency
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(formattedValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.white.opacity(0.6))
                .shadow(color: AppColors.shadowLight, radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var formattedValue: String {
        switch format {
        case .percentage:
            return String(format: "%.0f%%", value)
        case .fraction:
            if let total = total {
                return "\(Int(value))/\(Int(total))"
            }
            return "\(Int(value))"
        case .number:
            return "\(Int(value))"
        case .currency:
            return "$\(Int(value))"
        }
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        MetricCard(
            title: "Budget Used",
            value: 65,
            format: .percentage,
            icon: "dollarsign.circle.fill",
            color: .green
        )
        
        MetricCard(
            title: "Guests RSVP'd",
            value: 120,
            total: 180,
            format: .fraction,
            icon: "person.2.fill",
            color: .blue
        )
    }
    .padding()
    .frame(width: 600)
}
