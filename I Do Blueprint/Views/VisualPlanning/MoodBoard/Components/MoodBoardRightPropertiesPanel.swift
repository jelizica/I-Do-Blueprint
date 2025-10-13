//
//  MoodBoardRightPropertiesPanel.swift
//  My Wedding Planning App
//
//  Right properties panel for mood board editor
//

import SwiftUI

struct MoodBoardRightPropertiesPanel: View {
    @Binding var showingLayers: Bool
    @Binding var showingFilters: Bool
    @Binding var showingColorAdjustments: Bool

    let selectedElement: VisualElement?
    let canvasPropertiesContent: AnyView
    let elementPropertiesContent: AnyView?
    let filtersContent: AnyView
    let colorAdjustmentsContent: AnyView

    var body: some View {
        VStack(spacing: 0) {
            // Properties header
            HStack {
                Text("Properties")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showingLayers.toggle()
                }) {
                    Image(systemName: "square.3.layers.3d")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Canvas properties
                    canvasPropertiesContent

                    if elementPropertiesContent != nil {
                        Divider()
                        // Element properties
                        elementPropertiesContent
                    }

                    if showingFilters {
                        Divider()
                        // Filter controls
                        filtersContent
                    }

                    if showingColorAdjustments {
                        Divider()
                        // Color adjustments
                        colorAdjustmentsContent
                    }
                }
                .padding()
            }

            Spacer()
        }
        .frame(width: 280)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingLayers) {
            // Note: LayersPanel not found
            // LayersPanel(
            //     moodBoard: $editableMoodBoard,
            //     selectedElementId: $selectedElementId
            // )
            Text("Layers panel coming soon")
                .padding()
        }
    }
}
