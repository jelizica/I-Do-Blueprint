//
//  ColorQualityAnalyzer.swift
//  I Do Blueprint
//
//  Color quality and diversity analysis
//

import AppKit
import Foundation

/// Pure functions for color quality analysis
enum ColorQualityAnalyzer {
    
    // MARK: - Quality Score Calculation
    
    static func calculateQualityScore(
        for colors: [ExtractedColor],
        metadata: ExtractionMetadata
    ) -> Double {
        guard !colors.isEmpty else { return 0 }

        // Calculate diversity score
        let diversityScore = calculateColorDiversity(colors)

        // Calculate confidence score
        let avgConfidence = colors.map(\.confidence).reduce(0, +) / Double(colors.count)

        // Calculate population distribution score
        let populationScore = calculatePopulationDistribution(colors)

        // Weighted average
        return diversityScore * 0.4 + avgConfidence * 0.4 + populationScore * 0.2
    }
    
    // MARK: - Color Diversity
    
    static func calculateColorDiversity(_ colors: [ExtractedColor]) -> Double {
        guard colors.count > 1 else { return 0 }

        var totalDistance = 0.0
        var comparisons = 0

        for i in 0 ..< colors.count {
            for j in (i + 1) ..< colors.count {
                let color1 = colors[i].color
                let color2 = colors[j].color

                let distance = ColorSpaceConverter.calculateColorDistance(color1, color2)
                totalDistance += distance
                comparisons += 1
            }
        }

        return comparisons > 0 ? min(1.0, totalDistance / Double(comparisons)) : 0
    }
    
    // MARK: - Population Distribution
    
    static func calculatePopulationDistribution(_ colors: [ExtractedColor]) -> Double {
        let populations = colors.map(\.population).sorted(by: >)
        guard !populations.isEmpty else { return 0 }

        // Ideal distribution would be more even
        let entropy = populations.reduce(0) { entropy, population in
            population > 0 ? entropy - population * log2(population) : entropy
        }

        let maxEntropy = log2(Double(populations.count))
        return maxEntropy > 0 ? entropy / maxEntropy : 0
    }
}
