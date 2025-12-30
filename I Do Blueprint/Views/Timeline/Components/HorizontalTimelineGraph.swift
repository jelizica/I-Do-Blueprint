//
//  HorizontalTimelineGraph.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Horizontal timeline graph displaying items and milestones
struct HorizontalTimelineGraph: View {
    let items: [TimelineItem]
    let milestones: [Milestone]
    let onSelectItem: (TimelineItem) -> Void
    let onSelectMilestone: (Milestone) -> Void
    
    @State private var scrollPosition: CGFloat = 0
    @State private var hoveredId: UUID?
    
    /// User's calendar configured with their timezone - single source of truth for date operations
    private var userCalendar: Calendar {
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        return calendar
    }
    
    private var allDates: [Date] {
        let itemDates = items.map { $0.itemDate }
        let milestoneDates = milestones.map { $0.milestoneDate }
        return (itemDates + milestoneDates).sorted()
    }
    
    private var dateRange: (start: Date, end: Date) {
        guard let first = allDates.first, let last = allDates.last else {
            let now = Date()
            return (now, Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now)
        }
        
        // Add padding
        let start = Calendar.current.date(byAdding: .month, value: -1, to: first) ?? first
        let end = Calendar.current.date(byAdding: .month, value: 1, to: last) ?? last
        return (start, end)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                
                ZStack(alignment: .top) {
                    // Timeline axis
                    timelineAxis
                        .padding(.top, Spacing.huge)
                        .padding(.horizontal, Spacing.huge)
                        .offset(y: 0)
                    
                    // Event tracks - positioned to connect to the timeline
                    eventTracks
                        .padding(.horizontal, Spacing.huge)
                        .offset(y: 60)
                }
            }
            .frame(width: max(1200, CGFloat(allDates.count) * 120), height: 400)
        }
    }
    
    // MARK: - Timeline Axis
    
    private var timelineAxis: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let range = dateRange
            let totalDays = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1
            
            ZStack(alignment: .top) {
                // Main timeline line
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 2)
                    .offset(y: 20)
                
                // Month markers
                ForEach(Array(monthMarkers().enumerated()), id: \.offset) { index, monthData in
                    let position = positionForDate(monthData.date, in: range, width: width, totalDays: totalDays)
                    
                    VStack(spacing: 4) {
                        // Marker dot
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color(NSColor.controlBackgroundColor), lineWidth: 2)
                            )
                        
                        // Month label
                        Text(monthData.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 100)
                    }
                    .position(x: position, y: 20)
                }
            }
        }
        .frame(height: 80)
    }
    
    private func monthMarkers() -> [(date: Date, label: String)] {
        let range = dateRange
        var markers: [(date: Date, label: String)] = []
        
        // Use user's timezone for month markers
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        
        var currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: range.start))!
        
        while currentDate <= range.end {
            let label = DateFormatting.formatDate(currentDate, format: "MMM yyyy", timezone: userTimezone)
            markers.append((date: currentDate, label: label))
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }
        
        return markers
    }
    
    // MARK: - Event Tracks
    
    private var eventTracks: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let range = dateRange
            let totalDays = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1
            
            ZStack(alignment: .topLeading) {
                // All events positioned on the timeline with connecting lines
                ForEach(items) { item in
                    let position = positionForDate(item.itemDate, in: range, width: width, totalDays: totalDays)
                    
                    VStack(spacing: 0) {
                        // Connecting line from timeline to event
                        Rectangle()
                            .fill(Color(hex: item.itemType.color)?.opacity(0.3) ?? Color.blue.opacity(0.3))
                            .frame(width: 2, height: 50)
                        
                        // Event node
                        EventNode(item: item, isHovered: hoveredId == item.id)
                            .offset(y: -12) // Offset to center the circle on the line
                    }
                    .offset(x: position, y: 0)
                    .onTapGesture {
                        onSelectItem(item)
                    }
                    .onHover { isHovered in
                        hoveredId = isHovered ? item.id : nil
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func positionForDate(_ date: Date, in range: (start: Date, end: Date), width: CGFloat, totalDays: Int) -> CGFloat {
        let daysFromStart = Calendar.current.dateComponents([.day], from: range.start, to: date).day ?? 0
        let percentage = CGFloat(daysFromStart) / CGFloat(totalDays)
        return width * percentage
    }
    
    private func isMilestone(_ date: Date) -> Bool {
        // Use cached user calendar for date comparisons
        return milestones.contains { userCalendar.isDate($0.milestoneDate, inSameDayAs: date) }
    }
    
    private func milestoneForDate(_ date: Date) -> Milestone? {
        // Use cached user calendar for date comparisons
        return milestones.first { userCalendar.isDate($0.milestoneDate, inSameDayAs: date) }
    }
}
