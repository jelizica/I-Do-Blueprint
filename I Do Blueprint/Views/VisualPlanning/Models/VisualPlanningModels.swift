//
//  VisualPlanningModels.swift
//  I Do Blueprint
//
//  Shared models for visual planning navigation
//

import SwiftUI

enum VisualPlanningTab: CaseIterable, Hashable {
    case moodBoards
    case colorPalettes
    case stylePreferences
    case seatingChart
    
    var title: String {
        switch self {
        case .moodBoards: "Mood Boards"
        case .colorPalettes: "Color Palettes"
        case .stylePreferences: "Style Guide"
        case .seatingChart: "Seating Chart"
        }
    }
    
    var subtitle: String {
        switch self {
        case .moodBoards: "Visual inspiration boards"
        case .colorPalettes: "Wedding color schemes"
        case .stylePreferences: "Define your style"
        case .seatingChart: "Plan seating arrangements"
        }
    }
    
    var iconName: String {
        switch self {
        case .moodBoards: "photo.on.rectangle.angled"
        case .colorPalettes: "paintpalette"
        case .stylePreferences: "star.square"
        case .seatingChart: "tablecells"
        }
    }
    
    var color: Color {
        switch self {
        case .moodBoards: .blue
        case .colorPalettes: .purple
        case .stylePreferences: .orange
        case .seatingChart: .green
        }
    }
}
