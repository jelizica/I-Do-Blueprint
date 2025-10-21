//
//  SeatingChartHeader.swift
//  I Do Blueprint
//
//  Header component for seating chart editor with zoom controls and actions
//

import SwiftUI

struct SeatingChartHeader: View {
    let chartName: String
    let chartDescription: String?
    @Binding var canvasScale: CGFloat
    let onFitToView: () -> Void
    let onSave: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(chartName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let description = chartDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Canvas controls
            HStack(spacing: 8) {
                Button("Zoom Out") {
                    canvasScale = max(0.5, canvasScale - 0.1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(canvasScale <= 0.5)

                Text("\(Int(canvasScale * 100))%")
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 50)

                Button("Zoom In") {
                    canvasScale = min(2.0, canvasScale + 0.1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(canvasScale >= 2.0)

                Button("Fit to View") {
                    onFitToView()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)

                Button("Close") {
                    onClose()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    SeatingChartHeader(
        chartName: "Wedding Reception",
        chartDescription: "Main dining area",
        canvasScale: .constant(1.0),
        onFitToView: {},
        onSave: {},
        onClose: {}
    )
}
