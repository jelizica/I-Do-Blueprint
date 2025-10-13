//
//  DashboardViewV2.swift
//  My Wedding Planning App
//
//  Modular puzzle-piece dashboard with sharp edges and interlocking design
//  Created by Claude Code on 10/2/25.
//

import SwiftUI

struct DashboardViewV2: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingTaskModal = false
    @State private var showingNoteModal = false
    @State private var showingEventModal = false
    @State private var showingGuestModal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    QuickActionsBar(
                        showingTaskModal: $showingTaskModal,
                        showingNoteModal: $showingNoteModal,
                        showingEventModal: $showingEventModal,
                        showingGuestModal: $showingGuestModal
                    )

                    DashboardGridLayout(
                        summary: viewModel.summary,
                        weddingDate: viewModel.weddingDate,
                        daysUntilWedding: viewModel.daysUntilWedding
                    )
                    .padding()
                }
            }
            .background(DashboardColors.mainBackground)
            .navigationTitle("")
            .toolbar {
                DashboardToolbar(
                    isLoading: viewModel.isLoading,
                    onRefresh: viewModel.refresh
                )
            }
            .task {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $showingTaskModal) {
            Text("Task Modal")
        }
        .sheet(isPresented: $showingNoteModal) {
            Text("Note Modal")
        }
        .sheet(isPresented: $showingEventModal) {
            Text("Event Modal")
        }
        .sheet(isPresented: $showingGuestModal) {
            Text("Guest Modal")
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardViewV2()
        .frame(width: 1400, height: 900)
}
