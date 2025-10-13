//
//  MoodBoardCanvasPropertiesSection.swift
//  My Wedding Planning App
//
//  Canvas properties section for mood board editor
//

import SwiftUI

struct MoodBoardCanvasPropertiesSection: View {
    @Binding var editableMoodBoard: MoodBoard
    let historyManager: MoodBoardHistoryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Canvas")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Background Color")
                    .font(.caption)
                    .fontWeight(.medium)

                ColorPicker("Background", selection: $editableMoodBoard.backgroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(height: 40)
                    .onChange(of: editableMoodBoard.backgroundColor) { _, _ in
                        historyManager.addSnapshot(editableMoodBoard)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Canvas Size")
                    .font(.caption)
                    .fontWeight(.medium)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width")
                            .font(.caption2)
                        TextField(
                            "Width",
                            value: Binding(
                                get: { editableMoodBoard.canvasSize.width },
                                set: { if let newValue = $0 { editableMoodBoard.canvasSize.width = CGFloat(newValue) }
                                }),
                            format: .number)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height")
                            .font(.caption2)
                        TextField(
                            "Height",
                            value: Binding(
                                get: { editableMoodBoard.canvasSize.height },
                                set: { if let newValue = $0 { editableMoodBoard.canvasSize.height = CGFloat(newValue) }
                                }),
                            format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}
