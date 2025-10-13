//
//  RectangularTableLayoutManager.swift
//  My Wedding Planning App
//
//  Manages rectangular table layouts and positioning
//

import SwiftUI

enum RectangularLayoutStyle: String, CaseIterable {
    case banquetRows = "Banquet Rows"
    case uShape = "U-Shape"
    case hollowSquare = "Hollow Square"
    case boardroom = "Boardroom"
    case classroom = "Classroom"

    var description: String {
        switch self {
        case .banquetRows:
            "Long tables in parallel rows"
        case .uShape:
            "U-shaped arrangement"
        case .hollowSquare:
            "Square perimeter layout"
        case .boardroom:
            "Single long conference table"
        case .classroom:
            "All tables facing same direction"
        }
    }

    var icon: String {
        switch self {
        case .banquetRows: "rectangle.grid.3x2"
        case .uShape: "u.square"
        case .hollowSquare: "square.dashed"
        case .boardroom: "rectangle"
        case .classroom: "rectangle.3.group"
        }
    }
}

struct RectangularTableLayoutManager {
    var style: RectangularLayoutStyle
    var tablesPerRow: Int
    var rowSpacing: CGFloat
    var tableSpacing: CGFloat

    init(
        style: RectangularLayoutStyle = .banquetRows,
        tablesPerRow: Int = 3,
        rowSpacing: CGFloat = 150,
        tableSpacing: CGFloat = 80
    ) {
        self.style = style
        self.tablesPerRow = tablesPerRow
        self.rowSpacing = rowSpacing
        self.tableSpacing = tableSpacing
    }

    // MARK: - Generate Positions

    func generatePositions(count: Int, canvasSize: CGSize) -> [CGPoint] {
        switch style {
        case .banquetRows:
            return generateBanquetRowsPositions(count: count, canvasSize: canvasSize)
        case .uShape:
            return generateUShapePositions(count: count, canvasSize: canvasSize)
        case .hollowSquare:
            return generateHollowSquarePositions(count: count, canvasSize: canvasSize)
        case .boardroom:
            return generateBoardroomPositions(count: count, canvasSize: canvasSize)
        case .classroom:
            return generateClassroomPositions(count: count, canvasSize: canvasSize)
        }
    }

    // MARK: - Layout Implementations

    private func generateBanquetRowsPositions(count: Int, canvasSize: CGSize) -> [CGPoint] {
        var positions: [CGPoint] = []
        let rowCount = Int(ceil(Double(count) / Double(tablesPerRow)))

        let startX = canvasSize.width * 0.15
        let startY = canvasSize.height * 0.2

        for row in 0 ..< rowCount {
            let tablesInRow = min(tablesPerRow, count - row * tablesPerRow)

            for col in 0 ..< tablesInRow {
                let x = startX + CGFloat(col) * tableSpacing
                let y = startY + CGFloat(row) * rowSpacing

                positions.append(CGPoint(x: x, y: y))
            }
        }

        return positions
    }

    private func generateUShapePositions(count: Int, canvasSize: CGSize) -> [CGPoint] {
        var positions: [CGPoint] = []

        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2

        let uWidth = canvasSize.width * 0.6
        let uHeight = canvasSize.height * 0.5

        // Distribute tables around U shape
        let tablesPerSide = count / 3
        let remainder = count % 3

        // Top side (horizontal)
        let topCount = tablesPerSide + (remainder > 0 ? 1 : 0)
        for i in 0 ..< topCount {
            let x = centerX - uWidth / 2 + (uWidth / CGFloat(topCount + 1)) * CGFloat(i + 1)
            let y = centerY - uHeight / 2
            positions.append(CGPoint(x: x, y: y))
        }

        // Left side (vertical)
        let leftCount = tablesPerSide + (remainder > 1 ? 1 : 0)
        for i in 0 ..< leftCount {
            let x = centerX - uWidth / 2
            let y = centerY - uHeight / 2 + (uHeight / CGFloat(leftCount + 1)) * CGFloat(i + 1)
            positions.append(CGPoint(x: x, y: y))
        }

        // Right side (vertical)
        for i in 0 ..< tablesPerSide {
            let x = centerX + uWidth / 2
            let y = centerY - uHeight / 2 + (uHeight / CGFloat(tablesPerSide + 1)) * CGFloat(i + 1)
            positions.append(CGPoint(x: x, y: y))
        }

        return positions
    }

    private func generateHollowSquarePositions(count: Int, canvasSize: CGSize) -> [CGPoint] {
        var positions: [CGPoint] = []

        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let squareSize = min(canvasSize.width, canvasSize.height) * 0.6

        let tablesPerSide = count / 4
        let remainder = count % 4

        // Top side
        let topCount = tablesPerSide + (remainder > 0 ? 1 : 0)
        for i in 0 ..< topCount {
            let x = centerX - squareSize / 2 + (squareSize / CGFloat(topCount + 1)) * CGFloat(i + 1)
            let y = centerY - squareSize / 2
            positions.append(CGPoint(x: x, y: y))
        }

        // Right side
        let rightCount = tablesPerSide + (remainder > 1 ? 1 : 0)
        for i in 0 ..< rightCount {
            let x = centerX + squareSize / 2
            let y = centerY - squareSize / 2 + (squareSize / CGFloat(rightCount + 1)) * CGFloat(i + 1)
            positions.append(CGPoint(x: x, y: y))
        }

        // Bottom side
        let bottomCount = tablesPerSide + (remainder > 2 ? 1 : 0)
        for i in 0 ..< bottomCount {
            let x = centerX + squareSize / 2 - (squareSize / CGFloat(bottomCount + 1)) * CGFloat(i + 1)
            let y = centerY + squareSize / 2
            positions.append(CGPoint(x: x, y: y))
        }

        // Left side
        for i in 0 ..< tablesPerSide {
            let x = centerX - squareSize / 2
            let y = centerY + squareSize / 2 - (squareSize / CGFloat(tablesPerSide + 1)) * CGFloat(i + 1)
            positions.append(CGPoint(x: x, y: y))
        }

        return positions
    }

    private func generateBoardroomPositions(count: Int, canvasSize: CGSize) -> [CGPoint] {
        var positions: [CGPoint] = []

        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2

        // Single row of tables
        let totalWidth = CGFloat(count) * tableSpacing
        let startX = centerX - totalWidth / 2

        for i in 0 ..< count {
            let x = startX + CGFloat(i) * tableSpacing
            positions.append(CGPoint(x: x, y: centerY))
        }

        return positions
    }

    private func generateClassroomPositions(count: Int, canvasSize: CGSize) -> [CGPoint] {
        var positions: [CGPoint] = []

        let rowCount = Int(ceil(Double(count) / Double(tablesPerRow)))
        let startX = canvasSize.width * 0.2
        let startY = canvasSize.height * 0.25

        for row in 0 ..< rowCount {
            let tablesInRow = min(tablesPerRow, count - row * tablesPerRow)

            for col in 0 ..< tablesInRow {
                let x = startX + CGFloat(col) * tableSpacing
                let y = startY + CGFloat(row) * rowSpacing

                positions.append(CGPoint(x: x, y: y))
            }
        }

        return positions
    }

    // MARK: - Auto-arrange Tables

    func autoArrangeTables(_ tables: inout [Table], in canvasSize: CGSize) {
        let positions = generatePositions(count: tables.count, canvasSize: canvasSize)

        for (index, table) in tables.enumerated() {
            if index < positions.count {
                tables[index].position = positions[index]
            }
        }
    }

    // MARK: - Optimize Mixed Layout

    func optimizeMixedLayout(
        rectangularTables: [Table],
        circularTables: [Table],
        headTable: Table?,
        canvasSize: CGSize
    ) -> [UUID: CGPoint] {
        var positions: [UUID: CGPoint] = [:]

        var currentY: CGFloat = 100

        // Place head table at top (if exists)
        if let head = headTable {
            let centerX = canvasSize.width / 2
            positions[head.id] = CGPoint(x: centerX, y: currentY)
            currentY += 200
        }

        // Place rectangular tables in rows
        let rectPositions = generateBanquetRowsPositions(
            count: rectangularTables.count,
            canvasSize: canvasSize
        )
        for (index, table) in rectangularTables.enumerated() {
            if index < rectPositions.count {
                var pos = rectPositions[index]
                pos.y += currentY
                positions[table.id] = pos
            }
        }

        if !rectangularTables.isEmpty {
            currentY += CGFloat(Int(ceil(Double(rectangularTables.count) / Double(tablesPerRow)))) * rowSpacing + 100
        }

        // Place circular tables below
        let circularPositions = generateBanquetRowsPositions(
            count: circularTables.count,
            canvasSize: canvasSize
        )
        for (index, table) in circularTables.enumerated() {
            if index < circularPositions.count {
                var pos = circularPositions[index]
                pos.y += currentY
                positions[table.id] = pos
            }
        }

        return positions
    }
}
