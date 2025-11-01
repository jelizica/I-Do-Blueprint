//
//  SeatingChartCreatorView.swift
//  My Wedding Planning App
//
//  Creator/wizard for new seating charts
//

import SwiftUI

struct SeatingChartCreatorView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = SessionManager.shared

    @State private var chartName = ""
    @State private var eventName = "Reception"
    @State private var venueWidth: Double = 800
    @State private var venueHeight: Double = 600
    @State private var selectedTemplate: VenueTemplate = .rectangular
    @State private var includeCommonAreas = true
    @State private var expectedGuestCount: Int = 100

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "tablecells")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Create Seating Chart")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                }

                Text("Set up the basic information for your seating chart")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Chart Information
                    chartInformationSection

                    // Venue Dimensions
                    venueDimensionsSection

                    // Template Selection
                    templateSelectionSection

                    // Guest Count
                    guestCountSection

                    // Options
                    optionsSection
                }
                .padding()
            }

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Create Chart") {
                    createSeatingChart()
                }
                .buttonStyle(.borderedProminent)
                .disabled(chartName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }

    // MARK: - Chart Information Section

    private var chartInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chart Information")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Chart Name")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter chart name...", text: $chartName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Event Name")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter event name...", text: $eventName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Venue Dimensions Section

    private var venueDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Venue Dimensions")
                .font(.headline)

            Text("Approximate dimensions of your venue space")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Width")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        Slider(value: $venueWidth, in: 400 ... 2000, step: 50)
                        Text("\(Int(venueWidth)) ft")
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        Slider(value: $venueHeight, in: 300 ... 1500, step: 50)
                        Text("\(Int(venueHeight)) ft")
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }

            // Visual preview
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.textSecondary.opacity(0.1))
                    .frame(width: 200, height: 150)

                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(
                        width: 200 * (venueWidth / max(venueWidth, venueHeight)),
                        height: 150 * (venueHeight / max(venueWidth, venueHeight)))
            }
        }
    }

    // MARK: - Template Selection Section

    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Venue Layout Template")
                .font(.headline)

            Text("Choose a starting layout that matches your venue")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(VenueTemplate.allCases, id: \.self) { template in
                    VenueTemplateCard(
                        template: template,
                        isSelected: selectedTemplate == template) {
                        selectedTemplate = template
                    }
                }
            }
        }
    }

    // MARK: - Guest Count Section

    private var guestCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expected Guest Count")
                .font(.headline)

            Text("Approximate number of guests to help with table calculations")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Slider(value: Binding(
                    get: { Double(expectedGuestCount) },
                    set: { expectedGuestCount = Int($0) }), in: 20 ... 500, step: 10)

                Text("\(expectedGuestCount) guests")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 100, alignment: .trailing)
            }

            // Table count estimate
            let estimatedTables = Int(ceil(Double(expectedGuestCount) / 8.0))
            Text("Estimated \(estimatedTables) tables needed (assuming 8 guests per table)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)

            Toggle("Include common areas (bar, buffet, dance floor)", isOn: $includeCommonAreas)
                .font(.subheadline)
        }
    }

    // MARK: - Create Chart

    private func createSeatingChart() {
        let layout: VenueLayout = switch selectedTemplate {
        case .rectangular: .rectangular
        case .ballroom: .round
        case .garden: .garden
        case .barn, .loft: .rectangular
        }

        guard let tenantId = sessionManager.getTenantId() else {
            return
        }

        var newChart = SeatingChart(
            tenantId: tenantId.uuidString,
            chartName: chartName.trimmingCharacters(in: .whitespacesAndNewlines),
            eventId: nil,  // Future: Link to wedding event when events system is implemented
            venueLayoutType: layout,
            venueConfiguration: VenueConfiguration())

        // Load guests asynchronously after creation
        Task {
            // Create the chart first
            await visualPlanningStore.createSeatingChart(newChart)

            do {
                let service = SupabaseVisualPlanningService()
                let guests = try await service.fetchSeatingGuests(for: tenantId.uuidString)
                newChart.guests = guests

                // Update the chart with guests
                await visualPlanningStore.updateSeatingChart(newChart)
            } catch {
                AppLogger.ui.error("Failed to load guests", error: error)
            }

            dismiss()
        }
    }
}

// MARK: - Venue Template

enum VenueTemplate: CaseIterable {
    case rectangular, ballroom, garden, barn, loft

    var title: String {
        switch self {
        case .rectangular: "Rectangular Hall"
        case .ballroom: "Ballroom"
        case .garden: "Garden/Outdoor"
        case .barn: "Barn/Rustic"
        case .loft: "Loft/Industrial"
        }
    }

    var description: String {
        switch self {
        case .rectangular: "Traditional rectangular space"
        case .ballroom: "Round or oval ballroom"
        case .garden: "Outdoor garden setting"
        case .barn: "Rustic barn venue"
        case .loft: "Open loft space"
        }
    }

    var icon: String {
        switch self {
        case .rectangular: "rectangle"
        case .ballroom: "oval"
        case .garden: "leaf"
        case .barn: "house"
        case .loft: "building.2"
        }
    }

    func defaultObstacles(in dimensions: CGSize, includeCommonAreas: Bool) -> [VenueObstacle] {
        var obstacles: [VenueObstacle] = []

        guard includeCommonAreas else { return obstacles }

        let width = dimensions.width
        let height = dimensions.height

        switch self {
        case .rectangular:
            // Bar in corner
            obstacles.append(VenueObstacle(
                name: "Bar",
                position: CGPoint(x: width * 0.1, y: height * 0.1),
                size: CGSize(width: width * 0.15, height: height * 0.1),
                type: .bar))

            // Dance floor in center-back
            obstacles.append(VenueObstacle(
                name: "Dance Floor",
                position: CGPoint(x: width * 0.4, y: height * 0.8),
                size: CGSize(width: width * 0.2, height: height * 0.15),
                type: .danceFloor))

        case .ballroom:
            // Central dance floor
            obstacles.append(VenueObstacle(
                name: "Dance Floor",
                position: CGPoint(x: width * 0.4, y: height * 0.4),
                size: CGSize(width: width * 0.2, height: width * 0.2),
                type: .danceFloor))

            // Bar along one wall
            obstacles.append(VenueObstacle(
                name: "Bar",
                position: CGPoint(x: width * 0.05, y: height * 0.3),
                size: CGSize(width: width * 0.1, height: height * 0.4),
                type: .bar))

        case .garden:
            // Stage area
            obstacles.append(VenueObstacle(
                name: "Stage",
                position: CGPoint(x: width * 0.1, y: height * 0.85),
                size: CGSize(width: width * 0.2, height: height * 0.1),
                type: .stage))

        case .barn:
            // Buffet area
            obstacles.append(VenueObstacle(
                name: "Buffet",
                position: CGPoint(x: width * 0.8, y: height * 0.1),
                size: CGSize(width: width * 0.15, height: height * 0.2),
                type: .buffet))

        case .loft:
            // Bar
            obstacles.append(VenueObstacle(
                name: "Bar",
                position: CGPoint(x: width * 0.05, y: height * 0.1),
                size: CGSize(width: width * 0.2, height: height * 0.1),
                type: .bar))

            // DJ area
            obstacles.append(VenueObstacle(
                name: "DJ Station",
                position: CGPoint(x: width * 0.8, y: height * 0.85),
                size: CGSize(width: width * 0.15, height: height * 0.1),
                type: .dj))
        }

        return obstacles
    }
}

// MARK: - Supporting Views

struct VenueTemplateCard: View {
    let template: VenueTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.1) : AppColors.textSecondary.opacity(0.05))
                        .frame(height: 80)

                    Image(systemName: template.icon)
                        .font(.title)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }

                VStack(spacing: 2) {
                    Text(template.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .blue : .primary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
    }
}

#Preview {
    SeatingChartCreatorView()
        .environmentObject(VisualPlanningStoreV2())
}
