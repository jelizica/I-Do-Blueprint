//
//  GeometryHelpers.swift
//  My Wedding Planning App
//
//  Geometry calculations for seating charts
//  Created for Seating Chart V2
//

import Foundation
import SwiftUI

/// Helper utilities for geometric calculations in seating charts
struct GeometryHelpers {

    // MARK: - Rotation Transformation

    /// Transforms a drag translation to account for table rotation
    /// This fixes the bug where dragging rotated tables moves them in wrong directions
    /// - Parameters:
    ///   - translation: The drag gesture translation
    ///   - rotation: The table's rotation angle in degrees
    /// - Returns: Transformed translation that accounts for rotation
    static func transformTranslation(_ translation: CGSize, forRotation rotation: Double) -> CGSize {
        // Convert rotation to radians and invert (we want the inverse transformation)
        let radians = -rotation * .pi / 180.0
        let cos = CGFloat(Darwin.cos(radians))
        let sin = CGFloat(Darwin.sin(radians))

        // Apply inverse rotation matrix
        return CGSize(
            width: translation.width * cos - translation.height * sin,
            height: translation.width * sin + translation.height * cos
        )
    }

    // MARK: - Seat Positioning

    /// Calculates seat positions around a table
    /// - Parameters:
    ///   - tableShape: The shape of the table
    ///   - capacity: Number of seats
    ///   - tableSize: Size of the table
    ///   - avatarSize: Size of each avatar
    ///   - rotation: Table rotation in degrees
    /// - Returns: Array of positions for each seat
    static func seatPositions(
        for tableShape: TableShape,
        capacity: Int,
        tableSize: CGSize,
        avatarSize: CGFloat,
        rotation: Double
    ) -> [CGPoint] {
        guard capacity > 0 else { return [] }

        switch tableShape {
        case .round:
            return circularSeatPositions(
                capacity: capacity,
                radius: tableSize.width / 2,
                avatarSize: avatarSize,
                rotation: rotation
            )

        case .rectangular:
            return rectangularSeatPositions(
                capacity: capacity,
                size: tableSize,
                avatarSize: avatarSize,
                rotation: rotation
            )

        case .square:
            return squareSeatPositions(
                capacity: capacity,
                size: tableSize.width,
                avatarSize: avatarSize,
                rotation: rotation
            )

        case .oval:
            return ovalSeatPositions(
                capacity: capacity,
                size: tableSize,
                avatarSize: avatarSize,
                rotation: rotation
            )
        }
    }

    // MARK: - Private Seat Position Calculations

    /// Positions seats in a circle around a round table
    private static func circularSeatPositions(
        capacity: Int,
        radius: CGFloat,
        avatarSize: CGFloat,
        rotation: Double
    ) -> [CGPoint] {
        var positions: [CGPoint] = []
        let angleStep = 360.0 / Double(capacity)
        let seatRadius = radius + avatarSize * 0.75

        for i in 0..<capacity {
            // NOTE: We do NOT apply rotation here because TableViewV2 rotates the entire ZStack
            let angle = (angleStep * Double(i) - 90) * .pi / 180.0
            let x = CGFloat(Darwin.cos(angle)) * seatRadius
            let y = CGFloat(Darwin.sin(angle)) * seatRadius
            positions.append(CGPoint(x: x, y: y))
        }

        return positions
    }

    /// Positions seats around a rectangular table (long edges only)
    private static func rectangularSeatPositions(
        capacity: Int,
        size: CGSize,
        avatarSize: CGFloat,
        rotation: Double
    ) -> [CGPoint] {
        var positions: [CGPoint] = []
        let padding = avatarSize * 0.75

        // For rectangular tables, seats should ONLY be on the long edges
        // Determine which is the long edge
        let isWidthLonger = size.width >= size.height

        if isWidthLonger {
            // Seats on top and bottom edges
            let seatsPerSide = capacity / 2
            let extraSeat = capacity % 2

            // Top side
            let topCount = seatsPerSide + extraSeat
            if topCount > 0 {
                let spacing = size.width / CGFloat(topCount + 1)
                for i in 0..<topCount {
                    let x = -size.width / 2 + spacing * CGFloat(i + 1)
                    let y = -size.height / 2 - padding
                    positions.append(CGPoint(x: x, y: y))
                }
            }

            // Bottom side
            if seatsPerSide > 0 {
                let spacing = size.width / CGFloat(seatsPerSide + 1)
                for i in 0..<seatsPerSide {
                    let x = -size.width / 2 + spacing * CGFloat(i + 1)
                    let y = size.height / 2 + padding
                    positions.append(CGPoint(x: x, y: y))
                }
            }
        } else {
            // Seats on left and right edges
            let seatsPerSide = capacity / 2
            let extraSeat = capacity % 2

            // Left side
            let leftCount = seatsPerSide + extraSeat
            if leftCount > 0 {
                let spacing = size.height / CGFloat(leftCount + 1)
                for i in 0..<leftCount {
                    let x = -size.width / 2 - padding
                    let y = -size.height / 2 + spacing * CGFloat(i + 1)
                    positions.append(CGPoint(x: x, y: y))
                }
            }

            // Right side
            if seatsPerSide > 0 {
                let spacing = size.height / CGFloat(seatsPerSide + 1)
                for i in 0..<seatsPerSide {
                    let x = size.width / 2 + padding
                    let y = -size.height / 2 + spacing * CGFloat(i + 1)
                    positions.append(CGPoint(x: x, y: y))
                }
            }
        }

        // NOTE: We do NOT apply rotation here because TableViewV2 rotates the entire ZStack
        return positions
    }

    /// Positions seats around a square table
    private static func squareSeatPositions(
        capacity: Int,
        size: CGFloat,
        avatarSize: CGFloat,
        rotation: Double
    ) -> [CGPoint] {
        var positions: [CGPoint] = []
        let padding = avatarSize * 0.75
        let seatsPerSide = max(1, capacity / 4)
        let remainder = capacity - (seatsPerSide * 4)

        var seatIndex = 0

        // Top side
        for i in 0..<seatsPerSide {
            let x = -size / 2 + (size / CGFloat(seatsPerSide - 1)) * CGFloat(i)
            let y = -size / 2 - padding
            positions.append(CGPoint(x: x, y: y))
            seatIndex += 1
        }

        // Right side
        let rightCount = seatsPerSide + (remainder > 0 ? 1 : 0)
        for i in 0..<rightCount {
            let x = size / 2 + padding
            let y = -size / 2 + (size / CGFloat(rightCount - 1)) * CGFloat(i)
            positions.append(CGPoint(x: x, y: y))
            seatIndex += 1
        }

        // Bottom side
        let bottomCount = seatsPerSide + (remainder > 1 ? 1 : 0)
        for i in 0..<bottomCount {
            let x = size / 2 - (size / CGFloat(bottomCount - 1)) * CGFloat(i)
            let y = size / 2 + padding
            positions.append(CGPoint(x: x, y: y))
            seatIndex += 1
        }

        // Left side
        let leftCount = capacity - seatIndex
        for i in 0..<leftCount {
            let x = -size / 2 - padding
            let y = size / 2 - (size / CGFloat(leftCount - 1)) * CGFloat(i)
            positions.append(CGPoint(x: x, y: y))
        }

        // NOTE: We do NOT apply rotation here because TableViewV2 rotates the entire ZStack
        return positions
    }

    /// Positions seats around an oval table
    private static func ovalSeatPositions(
        capacity: Int,
        size: CGSize,
        avatarSize: CGFloat,
        rotation: Double
    ) -> [CGPoint] {
        var positions: [CGPoint] = []
        let angleStep = 360.0 / Double(capacity)
        let radiusX = (size.width / 2) + avatarSize * 0.75
        let radiusY = (size.height / 2) + avatarSize * 0.75

        for i in 0..<capacity {
            // NOTE: We do NOT apply rotation here because TableViewV2 rotates the entire ZStack
            let angle = (angleStep * Double(i) - 90) * .pi / 180.0
            let x = CGFloat(Darwin.cos(angle)) * radiusX
            let y = CGFloat(Darwin.sin(angle)) * radiusY
            positions.append(CGPoint(x: x, y: y))
        }

        return positions
    }

    /// Applies rotation to a point around the origin
    private static func applyRotation(_ point: CGPoint, rotation: Double) -> CGPoint {
        let radians = rotation * .pi / 180.0
        let cos = CGFloat(Darwin.cos(radians))
        let sin = CGFloat(Darwin.sin(radians))

        return CGPoint(
            x: point.x * cos - point.y * sin,
            y: point.x * sin + point.y * cos
        )
    }

    // MARK: - Table Dimensions

    /// Returns standard table dimensions for each table shape
    /// - Parameters:
    ///   - shape: Table shape
    ///   - capacity: Number of seats
    /// - Returns: Size of the table
    static func standardTableSize(for shape: TableShape, capacity: Int) -> CGSize {
        // Avatar with name takes ~60-80px width
        let avatarSpacing: CGFloat = 80

        switch shape {
        case .round:
            // Diameter based on capacity - ensure enough circumference for all avatars
            let diameter = max(120, CGFloat(capacity) * 20)
            return CGSize(width: diameter, height: diameter)

        case .rectangular:
            // Scale width based on number of seats per side
            // Seats are only on long edges, so divide capacity by 2
            let seatsPerSide = max(2, capacity / 2)
            let width = max(200, CGFloat(seatsPerSide) * avatarSpacing)
            let height = CGFloat(100) // Fixed height for rectangular tables
            return CGSize(width: width, height: height)

        case .square:
            // Square based on capacity - distribute on all 4 sides
            let seatsPerSide = max(2, capacity / 4)
            let size = max(150, CGFloat(seatsPerSide) * avatarSpacing)
            return CGSize(width: size, height: size)

        case .oval:
            // Oval dimensions - similar to rectangular but with curved edges
            let seatsPerSide = max(2, capacity / 2)
            let width = max(200, CGFloat(seatsPerSide) * avatarSpacing)
            let height = CGFloat(120)
            return CGSize(width: width, height: height)
        }
    }

    // MARK: - Distance Calculations

    /// Calculates distance between two points
    static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Checks if two rectangles overlap
    static func rectanglesOverlap(rect1: CGRect, rect2: CGRect) -> Bool {
        return rect1.intersects(rect2)
    }
}
