//
//  PerformanceDiagnosticsView.swift
//  I Do Blueprint
//
//  Developer diagnostics for performance metrics (DEBUG only UI)
//

import SwiftUI

#if DEBUG
struct PerformanceDiagnosticsView: View {
    @State private var events: [PerformanceMonitor.PerfEvent] = []
    @State private var stats: [PerformanceMonitor.PerfStats] = []
    @State private var filter: String = ""
    @State private var showSlowOnly: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            controls
            content
        }
        .padding(Spacing.lg)
        .onAppear { Task { await refresh() } }
        .navigationTitle("Performance Diagnostics")
        .frame(minWidth: 800, minHeight: 520)
    }

    private var header: some View {
        HStack {
            Text("Recent Performance Events")
                .font(.title2).bold()
            Spacer()
            Button("Refresh") { Task { await refresh() } }
            Button("Clear Metrics") { Task { await PerformanceMonitor.shared.clear(); await refresh() } }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            TextField("Filter by operation (e.g., budget.)", text: $filter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 320)

            Toggle("Show slow only", isOn: $showSlowOnly)
                .toggleStyle(.switch)

            Spacer()

            Toggle(isOn: Binding(
                get: { PerformanceFeatureFlags.enablePerformanceMonitoring },
                set: { PerformanceFeatureFlags.setPerformanceMonitoring(enabled: $0) }
            )) {
                Text("Verbose logging")
            }
            .help("Adds Sentry breadcrumbs for perf events when enabled")
        }
    }

    private var content: some View {
        HStack(spacing: Spacing.lg) {
            // Events list
            VStack(alignment: .leading) {
                List(filteredEvents().reversed()) { e in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.operation).font(.body).monospaced()
                            Text(e.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Total: \(formatMs(e.duration)) ms")
                            .font(.callout)
                        if let mt = e.mainThread {
                            Text("Main: \(formatMs(mt)) ms")
                                .font(.callout).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(minWidth: 460)

            // Stats summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Operation Stats").font(.headline)
                List(filteredStats(), id: \.id) { s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.operation).font(.body).monospaced()
                        HStack(spacing: 12) {
                            Text("count: \(s.count)")
                            Text("avg: \(formatMs(s.average))")
                            Text("p95: \(formatMs(s.p95))")
                            Text("med: \(formatMs(s.median))")
                            Text("min: \(formatMs(s.min))")
                            Text("max: \(formatMs(s.max))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                Spacer()
                HStack {
                    Button("Copy JSON") { copyJSON() }
                    Spacer()
                }
            }
            .frame(minWidth: 320)
        }
    }

    // MARK: - Helpers

    private func filteredEvents() -> [PerformanceMonitor.PerfEvent] {
        events.filter { e in
            (filter.isEmpty || e.operation.localizedCaseInsensitiveContains(filter)) &&
            (!showSlowOnly || e.duration >= 1.0)
        }
    }

    private func filteredStats() -> [PerformanceMonitor.PerfStats] {
        stats.filter { s in
            (filter.isEmpty || s.operation.localizedCaseInsensitiveContains(filter)) &&
            (!showSlowOnly || s.p95 >= 1.0)
        }
    }

    private func formatMs(_ seconds: TimeInterval) -> String {
        String(format: "%.0f", seconds * 1000)
    }

    private func copyJSON() {
        struct Snapshot: Codable { let events: [PerformanceMonitor.PerfEvent]; let stats: [PerformanceMonitor.PerfStats] }
        let snap = Snapshot(events: filteredEvents(), stats: filteredStats())
        if let data = try? JSONEncoder().encode(snap), let str = String(data: data, encoding: .utf8) {
            let p = NSPasteboard.general
            p.clearContents()
            p.setString(str, forType: .string)
        }
    }

    private func refresh() async {
        // Pull snapshots from actor
        events = await PerformanceMonitor.shared.getRecentEvents()
        stats = await PerformanceMonitor.shared.statisticsSnapshot()
    }
}
#endif
