//
//  AnalyticsCards.swift
//  I Do Blueprint
//
//  Card components for analytics dashboard
//

import SwiftUI

// MARK: - Overview Card

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()

                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Chart Card

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(insightTypeColor(insight.type))

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(insight.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Circle()
                    .fill(impactColor(insight.impact))
                    .frame(width: 8, height: 8)
            }

            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if insight.actionable {
                Button("Take Action") {
                    // Handle insight action
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insightTypeColor(insight.type).opacity(0.3), lineWidth: 1))
    }

    private func insightTypeColor(_ type: InsightType) -> Color {
        switch type {
        case .overspending: .red
        case .savings: .green
        case .seasonality: .blue
        case .vendor: .purple
        case .category: .orange
        case .timeline: .cyan
        case .recommendation: .blue
        case .warning: .yellow
        case .alert: .red
        case .info: .blue
        }
    }

    private func impactColor(_ impact: InsightImpact) -> Color {
        switch impact {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

// MARK: - Performance Metric Card

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let status: MetricStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Empty Insights View

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No insights available")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Continue using the app to generate insights")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
