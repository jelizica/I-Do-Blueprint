//
//  ExportViews.swift
//  My Wedding Planning App
//
//  Views optimized for export rendering (PDF, PNG, etc.)
//

import SwiftUI

// MARK: - Mood Board Export View

struct MoodBoardExportView: View {
    let moodBoard: MoodBoard

    var body: some View {
        ZStack {
            // Background
            moodBoard.backgroundColor

            // Elements
            ForEach(moodBoard.elements) { element in
                MoodBoardElementExportView(element: element)
            }

            // Title overlay (optional)
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(moodBoard.boardName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)

                        Text(moodBoard.styleCategory.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 1)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial))

                    Spacer()
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct MoodBoardElementExportView: View {
    let element: VisualElement

    @ViewBuilder
    var body: some View {
        switch element.elementType {
        case .image:
            if let imageUrl = element.elementData.imageUrl,
               let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

        case .color:
            RoundedRectangle(cornerRadius: 8)
                .fill(element.elementData.color ?? .gray)

        case .text:
            Text(element.elementData.text ?? "")
                .font(.system(size: max(12, element.size.height * 0.3)))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

        case .inspiration:
            VStack(spacing: 4) {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text(element.elementData.text ?? "Inspiration")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Mood Board Metadata View

struct MoodBoardMetadataView: View {
    let moodBoard: MoodBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood Board Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(moodBoard.boardName)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 1)
            }

            // Basic Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Information")
                    .font(.headline)

                MetadataRow(label: "Board Name", value: moodBoard.boardName)
                MetadataRow(label: "Style Category", value: moodBoard.styleCategory.displayName)
                MetadataRow(label: "Description", value: moodBoard.boardDescription ?? "No description")
                MetadataRow(
                    label: "Canvas Size",
                    value: "\(Int(moodBoard.canvasSize.width)) × \(Int(moodBoard.canvasSize.height))")
                MetadataRow(label: "Created", value: DateFormatter.standard.string(from: moodBoard.createdAt))
                MetadataRow(label: "Updated", value: DateFormatter.standard.string(from: moodBoard.updatedAt))
            }

            // Elements Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Elements Summary")
                    .font(.headline)

                let elementCounts = Dictionary(grouping: moodBoard.elements, by: { $0.elementType })
                    .mapValues { $0.count }

                ForEach(ElementType.allCases, id: \.self) { type in
                    if let count = elementCounts[type], count > 0 {
                        MetadataRow(label: type.displayName, value: "\(count)")
                    }
                }

                MetadataRow(label: "Total Elements", value: "\(moodBoard.elements.count)")
            }

            // Color Analysis
            if let dominantColors = extractDominantColors() {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Analysis")
                        .font(.headline)

                    Text("Dominant Colors")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        ForEach(Array(dominantColors.enumerated()), id: \.offset) { _, color in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)

                                Text(color.hexString)
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("Generated by My Wedding Planning App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color.white)
    }

    private func extractDominantColors() -> [Color]? {
        let colors = moodBoard.elements
            .compactMap(\.elementData.color)
            .filter { $0 != .clear && $0 != .white }

        return Array(Set(colors)).prefix(5).map { $0 }
    }
}

// MARK: - Color Palette Export View

struct ColorPaletteExportView: View {
    let palette: ColorPalette
    let includeHexCodes: Bool

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Text("Wedding Color Palette")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(palette.name)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 2)
                    .frame(maxWidth: 400)
            }

            // Main color swatches
            VStack(spacing: 24) {
                Text("Primary Colors")
                    .font(.headline)

                HStack(spacing: 20) {
                    // Display colors from the colors array
                    let colorLabels = ["Primary", "Secondary", "Accent", "Neutral"]
                    ForEach(palette.colors.prefix(4).indices, id: \.self) { index in
                        if let color = Color.fromHexString(palette.colors[index]) {
                            ColorSwatchExport(
                                color: color,
                                label: index < colorLabels.count ? colorLabels[index] : "Color \(index + 1)",
                                includeHex: includeHexCodes)
                        }
                    }
                }
            }

            // Additional colors if available (beyond the first 4)
            if palette.colors.count > 4 {
                VStack(spacing: 16) {
                    Text("Additional Colors")
                        .font(.headline)

                    HStack(spacing: 16) {
                        ForEach(palette.colors.dropFirst(4).indices, id: \.self) { index in
                            if let color = Color.fromHexString(palette.colors[index]) {
                                ColorSwatchExport(
                                    color: color,
                                    label: "Color \(index - 3)",
                                    includeHex: includeHexCodes)
                            }
                        }
                    }
                }
            }

            // Color strip
            VStack(spacing: 12) {
                Text("Color Strip")
                    .font(.headline)

                HStack(spacing: 0) {
                    ForEach(palette.colors, id: \.self) { hexColor in
                        Rectangle().fill(Color.fromHexString(hexColor) ?? .gray)
                    }
                }
                .frame(height: 60)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4)
            }

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                if let description = palette.description {
                    MetadataRow(label: "Description", value: description)
                }

                MetadataRow(label: "Default", value: palette.isDefault ? "Yes" : "No")

                MetadataRow(label: "Created", value: DateFormatter.standard.string(from: palette.createdAt))
            }

            Spacer()

            // Footer
            HStack {
                Text("My Wedding Planning App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color.white)
    }
}

struct ColorSwatchExport: View {
    let color: Color
    let label: String
    let includeHex: Bool

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 4)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)

            if includeHex {
                Text(color.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Seating Chart Export View

struct SeatingChartExportView: View {
    let chart: SeatingChart

    var body: some View {
        ZStack {
            // Background
            Color.white

            // Venue obstacles
            // Note: SeatingChart doesn't have venueLayout property
            // ForEach(chart.venueLayout.obstacles) { obstacle in
            //     RoundedRectangle(cornerRadius: 4)
            //         .fill(obstacle.obstacleType.defaultColor.opacity(0.3))
            //         .frame(width: obstacle.size.width, height: obstacle.size.height)
            //         .position(obstacle.position)
            //         .overlay(
            //             Text(obstacle.name)
            //                 .font(.caption)
            //                 .fontWeight(.medium)
            //                 .position(obstacle.position)
            //         )
            // }

            // Tables
            ForEach(chart.tables) { table in
                TableExportView(
                    table: table,
                    assignments: chart.seatingAssignments.filter { $0.tableId == table.id },
                    guests: chart.guests)
            }

            // Title overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chart.chartName)
                            .font(.title)
                            .fontWeight(.bold)

                        if let eventId = chart.eventId {
                            Text("Event ID: \(eventId.uuidString)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("\(chart.guests.count) guests • \(chart.tables.count) tables")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4))

                    Spacer()
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct TableExportView: View {
    let table: Table
    let assignments: [SeatingAssignment]
    let guests: [SeatingGuest]

    @ViewBuilder
    var body: some View {
        ZStack {
            // Table shape
            Group {
                switch table.tableShape {
                case .round:
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))

                case .square:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))

                case .rectangular:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))

                case .oval:
                    Ellipse()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(Ellipse().stroke(Color.blue, lineWidth: 2))
                }
            }
            .frame(width: 100, height: 100)

            // Table number and guest count
            VStack(spacing: 2) {
                Text("Table \(table.tableNumber)")
                    .font(.subheadline)
                    .fontWeight(.bold)

                if !assignments.isEmpty {
                    Text("\(assignments.count)/\(table.capacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .rotationEffect(.degrees(table.rotation))
        .position(table.position)
    }
}

// MARK: - Guest List Export View

struct GuestListExportView: View {
    let chart: SeatingChart

    private var guestsByTable: [Int: [SeatingGuest]] {
        var result: [Int: [SeatingGuest]] = [:]

        for assignment in chart.seatingAssignments {
            guard let guest = chart.guests.first(where: { $0.id == assignment.guestId }),
                  let table = chart.tables.first(where: { $0.id == assignment.tableId }) else { continue }

            if result[table.tableNumber] == nil {
                result[table.tableNumber] = []
            }
            result[table.tableNumber]?.append(guest)
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Guest Seating List")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(chart.chartName)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 1)
            }

            // Summary
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Guests")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chart.guests.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Assigned")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chart.seatingAssignments.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tables")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chart.tables.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            // Tables and guests
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(chart.tables.sorted(by: { $0.tableNumber < $1.tableNumber }), id: \.id) { table in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Table \(table.tableNumber)")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                if let tableName = table.tableName {
                                    Text("(\(tableName))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                let assignedGuests = guestsByTable[table.tableNumber] ?? []
                                Text("\(assignedGuests.count)/\(table.capacity)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(assignedGuests.count == table.capacity ? .green : .orange)
                            }

                            if let guests = guestsByTable[table.tableNumber], !guests.isEmpty {
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2),
                                    spacing: 4) {
                                    ForEach(guests.sorted(by: { $0.lastName < $1.lastName }), id: \.id) { guest in
                                        HStack {
                                            Circle()
                                                .fill(guest.relationship.color)
                                                .frame(width: 8, height: 8)

                                            Text(guest.fullName)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            } else {
                                Text("No guests assigned")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("My Wedding Planning App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color.white)
    }
}

// MARK: - Supporting Views

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
