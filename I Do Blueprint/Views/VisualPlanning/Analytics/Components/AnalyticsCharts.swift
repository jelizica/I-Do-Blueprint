//
//  AnalyticsCharts.swift
//  I Do Blueprint
//
//  Chart components for analytics dashboard
//

import Charts
import SwiftUI

// MARK: - Activity Chart

struct ActivityChart: View {
    let data: [ActivityMetric]

    var body: some View {
        Chart(data, id: \.date) { metric in
            LineMark(
                x: .value("Date", metric.date),
                y: .value("Total", metric.total))
                .foregroundStyle(.blue)

            AreaMark(
                x: .value("Date", metric.date),
                y: .value("Total", metric.total))
                .foregroundStyle(.blue.opacity(0.1))
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
}

// MARK: - Style Distribution Chart

struct StyleDistributionChart: View {
    let data: [StyleCategory: Int]

    var body: some View {
        Chart(data.sorted { $0.value > $1.value }, id: \.key) { item in
            BarMark(
                x: .value("Count", item.value),
                y: .value("Style", item.key.displayName))
                .foregroundStyle(by: .value("Style", item.key.displayName))
        }
        .frame(height: 200)
        .chartLegend(.hidden)
    }
}

// MARK: - Dominant Colors Chart

struct DominantColorsChart: View {
    let data: [ColorFrequency]

    var body: some View {
        Chart(data.prefix(8), id: \.color.description) { colorFreq in
            BarMark(
                x: .value("Frequency", colorFreq.frequency),
                y: .value("Color", colorFreq.color.description))
                .foregroundStyle(colorFreq.color)
        }
        .frame(height: 200)
    }
}

// MARK: - Usage Patterns Chart

struct UsagePatternsChart: View {
    let timePatterns: TimePatterns
    let selectedTimeframe: TimeFrame

    var body: some View {
        VStack {
            if selectedTimeframe == .day {
                Chart(timePatterns.hourlyActivity.sorted { $0.key < $1.key }, id: \.key) { item in
                    BarMark(
                        x: .value("Hour", item.key),
                        y: .value("Activity", item.value))
                        .foregroundStyle(.green)
                }
                .chartXAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 23, by: 4))) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel("\(value.as(Int.self) ?? 0):00")
                    }
                }
            } else {
                Chart(timePatterns.dailyActivity.sorted { $0.key < $1.key }, id: \.key) { item in
                    BarMark(
                        x: .value("Day", weekdayName(item.key)),
                        y: .value("Activity", item.value))
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(height: 200)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return weekdays[weekday - 1]
    }
}
