//
//  BudgetCalculatorAddContributionSheet.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct BudgetCalculatorAddContributionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contributorName = ""
    @State private var amount = ""
    @State private var contributionType: ContributionType = .gift
    @State private var contributionDate = Date()
    @State private var notes = ""
    let onSave: (String, Double, ContributionType, Date?) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Gift or Contribution")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                TextField("Name (e.g., Amy & Bob Gilchrist)", text: $contributorName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("$")
                    TextField("Amount", text: $amount)
                        .textFieldStyle(.roundedBorder)
                }

                Picker("Type", selection: $contributionType) {
                    ForEach(ContributionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker("Date", selection: $contributionDate, displayedComponents: .date)

                TextField("Notes (optional)", text: $notes)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    if let amountValue = Double(amount) {
                        onSave(contributorName, amountValue, contributionType, contributionDate)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(contributorName.isEmpty || amount.isEmpty)
            }
        }
        .padding(Spacing.xxl)
        .frame(width: 500)
    }
}
