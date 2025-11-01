//
//  DashboardToolbar.swift
//  My Wedding Planning App
//
//  Toolbar component for dashboard refresh action
//  Created by Claude Code on 1/9/25.
//

import SwiftUI

struct DashboardToolbar: ToolbarContent {
    let isLoading: Bool
    let onRefresh: () async -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button(action: {
                Task { await onRefresh() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(AppColors.textPrimary)
            }
            .disabled(isLoading)
            .accessibilityLabel("Refresh Dashboard")
            .accessibilityHint("Reloads all dashboard data")
        }
    }
}
