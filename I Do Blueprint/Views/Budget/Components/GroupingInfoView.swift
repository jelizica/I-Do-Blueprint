//
//  GroupingInfoView.swift
//  I Do Blueprint
//
//  Information popover explaining payment plan grouping strategies
//

import SwiftUI

struct GroupingInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Plan Grouping")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Choose how to group your payment schedules:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            ForEach(PaymentPlanGroupingStrategy.allCases, id: \.self) { strategy in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: strategy.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(strategy.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                
                if strategy != PaymentPlanGroupingStrategy.allCases.last {
                    Divider()
                }
            }
            
            Spacer()
            
            Text("Your preference is saved automatically.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}
