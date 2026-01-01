//
//  GeometryReaderTestView.swift
//  I Do Blueprint
//
//  Debug view to test GeometryReader width measurement in NavigationSplitView detail pane
//

import SwiftUI

struct GeometryReaderTestView: View {
    @State private var outerWidth: CGFloat = 0
    @State private var innerWidth: CGFloat = 0
    @State private var measurements: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("GeometryReader Measurement Test")
                .font(.title)

            VStack(alignment: .leading, spacing: 10) {
                Text("📊 Measurements:")
                    .font(.headline)

                Text("Full Window Width: \(Int(outerWidth))px")
                    .foregroundColor(.blue)

                Text("Detail Pane Width: \(Int(innerWidth))px")
                    .foregroundColor(.green)

                Text("Difference (Sidebar): \(Int(outerWidth - innerWidth))px")
                    .foregroundColor(.orange)

                Divider()

                Text("📝 Measurement Log:")
                    .font(.headline)

                ForEach(Array(measurements.enumerated()), id: \.offset) { _, measurement in
                    Text(measurement)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .onAppear {
            addMeasurement("View appeared")
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        innerWidth = geometry.size.width
                        addMeasurement("Inner GeometryReader: \(Int(geometry.size.width))px")
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        innerWidth = newWidth
                        addMeasurement("Inner width changed to: \(Int(newWidth))px")
                    }
            }
        )
    }

    private func addMeasurement(_ text: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        measurements.append("[\(timestamp)] \(text)")
    }
}

// MARK: - Test Container

/// This mimics the RootFlowView structure to test nested GeometryReader behavior
struct GeometryReaderTestContainer: View {
    @State private var outerWidth: CGFloat = 0

    var body: some View {
        GeometryReader { outerGeometry in
            NavigationSplitView {
                // Sidebar
                List {
                    Text("Sidebar Item 1")
                    Text("Sidebar Item 2")
                    Text("Sidebar Item 3")
                }
                .navigationTitle("Sidebar")
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            } detail: {
                // Detail pane with our test view
                GeometryReaderTestView()
            }
            .navigationSplitViewStyle(.balanced)
            .onAppear {
                outerWidth = outerGeometry.size.width
            }
            .onChange(of: outerGeometry.size.width) { _, newWidth in
                outerWidth = newWidth
            }
        }
    }
}

// MARK: - Preview

#Preview("Test in NavigationSplitView") {
    GeometryReaderTestContainer()
        .frame(width: 699, height: 600)
}

#Preview("Test at 1024px") {
    GeometryReaderTestContainer()
        .frame(width: 1024, height: 600)
}

#Preview("Test at 640px") {
    GeometryReaderTestContainer()
        .frame(width: 640, height: 600)
}
