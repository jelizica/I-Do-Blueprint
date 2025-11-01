//
//  MinimapView.swift
//  My Wedding Planning App
//
//  Minimap component showing overview of table layout
//

import SwiftUI

struct MinimapView: View {
    let tables: [Table]
    let canvasSize: CGSize
    let canvasScale: CGFloat
    let canvasOffset: CGPoint
    let viewportSize: CGSize

    private let minimapScale: CGFloat = 0.05 // Scale down entire layout for minimap

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            // Border
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)

            // Tables at small scale
            ForEach(tables) { table in
                Circle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .position(
                        x: table.position.x * minimapScale + 75,
                        y: table.position.y * minimapScale + 50)
            }

            // Viewport indicator (shows current visible area)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.green, lineWidth: 2)
                .frame(
                    width: viewportSize.width * minimapScale / canvasScale,
                    height: viewportSize.height * minimapScale / canvasScale)
                .position(
                    x: 75 - (canvasOffset.x * minimapScale / canvasScale),
                    y: 50 - (canvasOffset.y * minimapScale / canvasScale))

            // Label
            VStack {
                Spacer()
                Text("OVERVIEW")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, Spacing.xs)
            }
        }
        .frame(width: 150, height: 100)
    }
}
