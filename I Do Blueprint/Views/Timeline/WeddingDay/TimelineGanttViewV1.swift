//
//  TimelineGanttViewV1.swift
//  I Do Blueprint
//
//  Wedding Day Timeline - Gantt Chart View
//  Horizontal timeline with event bars, dependency lines, and time markers
//

import SwiftUI

struct TimelineGanttViewV1: View {
    @EnvironmentObject private var store: TimelineStoreV2

    // MARK: - State
    @State private var selectedEvent: WeddingDayEvent?
    @State private var showingEventDetail = false
    @State private var scrollProxy: ScrollViewProxy?

    // MARK: - Constants
    private let hourWidth: CGFloat = 120
    private let rowHeight: CGFloat = 50
    private let headerHeight: CGFloat = 60
    private let labelWidth: CGFloat = 180

    // MARK: - Computed Properties

    private var sortedEvents: [WeddingDayEvent] {
        store.weddingDayEvents.sorted { event1, event2 in
            guard let start1 = event1.startTime, let start2 = event2.startTime else {
                return event1.eventOrder < event2.eventOrder
            }
            return start1 < start2
        }
    }

    private var timeRange: (start: Int, end: Int) {
        let events = sortedEvents
        guard !events.isEmpty else {
            return (start: 8, end: 20) // Default 8 AM to 8 PM
        }

        let calendar = Calendar.current
        var minHour = 24
        var maxHour = 0

        for event in events {
            if let startTime = event.startTime {
                let hour = calendar.component(.hour, from: startTime)
                minHour = min(minHour, hour)
            }
            if let endTime = event.endTime {
                let hour = calendar.component(.hour, from: endTime)
                maxHour = max(maxHour, hour + 1)
            }
        }

        // Add padding hours
        return (start: max(0, minHour - 1), end: min(24, maxHour + 1))
    }

    private var totalWidth: CGFloat {
        CGFloat(timeRange.end - timeRange.start) * hourWidth
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Fixed event labels column
                eventLabelsColumn

                // Scrollable Gantt chart area
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: true) {
                        VStack(spacing: 0) {
                            // Time header
                            timeHeader

                            // Event bars with grid
                            ZStack(alignment: .topLeading) {
                                // Background grid
                                gridBackground

                                // Current time indicator
                                currentTimeIndicator

                                // Event bars
                                eventBarsView

                                // Dependency lines
                                dependencyLinesView
                            }
                        }
                        .frame(width: totalWidth)
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }
            .background(TimelineColors.glassBackground.opacity(0.5))
        }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                WeddingDayEventDetailSheet(event: event, onDismiss: {
                    selectedEvent = nil
                    showingEventDetail = false
                })
            }
        }
    }

    // MARK: - Event Labels Column

    private var eventLabelsColumn: some View {
        VStack(spacing: 0) {
            // Header spacer
            Rectangle()
                .fill(Color.clear)
                .frame(height: headerHeight)
                .overlay(
                    Text("Events")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, Spacing.md)
                )
                .background(TimelineColors.glassBackground.background(.ultraThinMaterial))

            Divider()

            // Event labels
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(sortedEvents) { event in
                        eventLabel(event: event)
                    }
                }
            }
        }
        .frame(width: labelWidth)
        .background(TimelineColors.glassBackground.background(.ultraThinMaterial))
    }

    private func eventLabel(event: WeddingDayEvent) -> some View {
        HStack(spacing: Spacing.sm) {
            // Category indicator
            Circle()
                .fill(event.category.color)
                .frame(width: 8, height: 8)

            // Event name
            Text(event.eventName)
                .font(Typography.subheading)
                .fontWeight(event.isHighlighted ? .semibold : .regular)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: rowHeight)
        .background(
            event.isHighlighted
                ? event.category.color.opacity(0.1)
                : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(TimelineColors.glassBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Time Header

    private var timeHeader: some View {
        HStack(spacing: 0) {
            ForEach(timeRange.start..<timeRange.end, id: \.self) { hour in
                VStack(spacing: Spacing.xs) {
                    Text(formatHour(hour))
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(TimelineColors.ganttHourLabel)

                    // Quarter-hour markers
                    HStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { quarter in
                            Rectangle()
                                .fill(quarter == 0 ? TimelineColors.ganttHourMarker : TimelineColors.ganttHourMarker.opacity(0.3))
                                .frame(width: 1, height: quarter == 0 ? 12 : 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(width: hourWidth)
            }
        }
        .frame(height: headerHeight)
        .background(TimelineColors.glassBackground.background(.ultraThinMaterial))
        .overlay(
            Rectangle()
                .fill(TimelineColors.glassBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Grid Background

    private var gridBackground: some View {
        VStack(spacing: 0) {
            ForEach(0..<sortedEvents.count, id: \.self) { _ in
                HStack(spacing: 0) {
                    ForEach(timeRange.start..<timeRange.end, id: \.self) { hour in
                        Rectangle()
                            .stroke(TimelineColors.ganttHourMarker.opacity(0.3), lineWidth: 0.5)
                            .frame(width: hourWidth, height: rowHeight)
                    }
                }
            }
        }
    }

    // MARK: - Current Time Indicator

    @ViewBuilder
    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        if hour >= timeRange.start && hour < timeRange.end {
            let position = CGFloat(hour - timeRange.start) * hourWidth + CGFloat(minute) / 60.0 * hourWidth

            Rectangle()
                .fill(TimelineColors.ganttCurrentTime)
                .frame(width: 2)
                .frame(height: CGFloat(sortedEvents.count) * rowHeight)
                .offset(x: position)

            // Current time label
            Text(formatTime(now))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(TimelineColors.ganttCurrentTime)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .offset(x: position - 20, y: -20)
        }
    }

    // MARK: - Event Bars

    private var eventBarsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                eventBar(event: event, rowIndex: index)
                    .frame(height: rowHeight)
            }
        }
    }

    private func eventBar(event: WeddingDayEvent, rowIndex: Int) -> some View {
        GeometryReader { _ in
            if event.startTime != nil {
                let barPosition = calculateBarPosition(for: event)
                let barWidth = calculateBarWidth(for: event)

                Button {
                    selectedEvent = event
                    showingEventDetail = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        // Event icon
                        Image(systemName: event.displayIcon)
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        // Event name (if space permits)
                        if barWidth > 100 {
                            Text(event.eventName)
                                .font(Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        // Duration label
                        if barWidth > 80 {
                            Text("\(event.calculatedDurationMinutes)m")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .frame(width: barWidth, height: rowHeight - 12)
                    .background(
                        LinearGradient(
                            colors: [
                                event.category.color,
                                event.category.color.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(event.category.color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: event.category.color.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .offset(x: barPosition, y: 6)
            }
        }
    }

    // MARK: - Dependency Lines

    private var dependencyLinesView: some View {
        Canvas { context, size in
            let events = sortedEvents
            let eventPositions = Dictionary(uniqueKeysWithValues: events.enumerated().map { ($1.id, $0) })

            for event in events {
                guard let dependsOnId = event.dependsOnEventId,
                      let sourceIndex = eventPositions[dependsOnId],
                      let targetIndex = eventPositions[event.id],
                      let sourceEvent = events.first(where: { $0.id == dependsOnId }) else {
                    continue
                }

                let sourceEndX = calculateBarPosition(for: sourceEvent) + calculateBarWidth(for: sourceEvent)
                let sourceY = CGFloat(sourceIndex) * rowHeight + rowHeight / 2

                let targetStartX = calculateBarPosition(for: event)
                let targetY = CGFloat(targetIndex) * rowHeight + rowHeight / 2

                // Draw bezier curve for dependency
                var path = Path()
                path.move(to: CGPoint(x: sourceEndX, y: sourceY))

                let controlX = (sourceEndX + targetStartX) / 2
                path.addCurve(
                    to: CGPoint(x: targetStartX, y: targetY),
                    control1: CGPoint(x: controlX, y: sourceY),
                    control2: CGPoint(x: controlX, y: targetY)
                )

                context.stroke(
                    path,
                    with: .color(TimelineColors.ganttDependencyLine),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                )

                // Draw arrow at target
                let arrowSize: CGFloat = 8
                var arrowPath = Path()
                arrowPath.move(to: CGPoint(x: targetStartX, y: targetY))
                arrowPath.addLine(to: CGPoint(x: targetStartX - arrowSize, y: targetY - arrowSize / 2))
                arrowPath.addLine(to: CGPoint(x: targetStartX - arrowSize, y: targetY + arrowSize / 2))
                arrowPath.closeSubpath()

                context.fill(arrowPath, with: .color(TimelineColors.ganttDependencyLine))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helper Methods

    private func calculateBarPosition(for event: WeddingDayEvent) -> CGFloat {
        guard let startTime = event.startTime else { return 0 }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)

        let hoursFromStart = CGFloat(hour - timeRange.start)
        let minuteFraction = CGFloat(minute) / 60.0

        return (hoursFromStart + minuteFraction) * hourWidth
    }

    private func calculateBarWidth(for event: WeddingDayEvent) -> CGFloat {
        let durationMinutes = event.calculatedDurationMinutes
        let width = CGFloat(durationMinutes) / 60.0 * hourWidth

        // Minimum width for visibility
        return max(width, 40)
    }

    private func formatHour(_ hour: Int) -> String {
        let adjustedHour = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return "\(adjustedHour) \(period)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    TimelineGanttViewV1()
        .environmentObject(TimelineStoreV2())
        .frame(width: 1200, height: 600)
}
