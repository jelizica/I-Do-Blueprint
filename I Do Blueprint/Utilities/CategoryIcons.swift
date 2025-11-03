import SwiftUI

/// Centralized category icon and color mapping for budget items
struct CategoryIcons {

    // MARK: - Icon Mapping

    private static let iconMap: [String: String] = [
        // Venue & Location
        "venue": "building.2.fill",
        "venues": "building.2.fill",
        "accommodation": "bed.double.fill",
        "hotel": "bed.double.fill",
        
        // Food & Beverage
        "catering": "fork.knife",
        "food": "fork.knife",
        "food & beverage": "fork.knife",
        "cake": "birthday.cake.fill",
        "dessert": "birthday.cake.fill",
        "bar": "wineglass.fill",
        "beverage": "wineglass.fill",
        
        // Photography & Videography
        "photography": "camera.fill",
        "photographer": "camera.fill",
        "videography": "video.fill",
        "video": "video.fill",
        
        // Entertainment
        "music": "music.note",
        "entertainment": "music.note",
        "dj": "music.note",
        "band": "music.mic",
        "live music": "music.mic",
        
        // Flowers & Decorations
        "flowers": "leaf.fill",
        "floral": "leaf.fill",
        "decorations": "sparkles",
        "decor": "sparkles",
        
        // Attire & Beauty
        "attire": "tshirt.fill",
        "clothing": "tshirt.fill",
        "dress": "figure.dress.line.vertical.figure",
        "gown": "figure.dress.line.vertical.figure",
        "suit": "person.fill",
        "tuxedo": "person.fill",
        "hair": "comb.fill",
        "makeup": "comb.fill",
        "beauty": "comb.fill",
        "jewelry": "crown.fill",
        "accessories": "crown.fill",
        
        // Transportation
        "transportation": "car.fill",
        "transport": "car.fill",
        "limo": "car.side.fill",
        "limousine": "car.side.fill",
        
        // Stationery & Paper
        "invitations": "envelope.fill",
        "stationery": "envelope.fill",
        "favors": "gift.fill",
        "gifts": "gift.fill",
        
        // Planning & Services
        "planner": "calendar.badge.checkmark",
        "coordinator": "calendar.badge.checkmark",
        "officiant": "person.2.fill",
        
        // Miscellaneous
        "miscellaneous": "star.fill",
        "other": "star.fill",
        "rentals": "house.fill",
        "rental": "house.fill",
        "insurance": "shield.fill"
    ]

    /// Returns the SF Symbol icon name for a given category
    static func icon(for category: String) -> String {
        iconMap[category.lowercased()] ?? "dollarsign.circle.fill"
    }

    // MARK: - Color Mapping

    private static let colorMap: [String: Color] = [
        // Venue & Location
        "venue": .purple,
        "venues": .purple,
        "accommodation": .teal,
        "hotel": .teal,
        
        // Food & Beverage
        "catering": .orange,
        "food": .orange,
        "food & beverage": .orange,
        "cake": .pink,
        "dessert": .pink,
        "bar": .red,
        "beverage": .red,
        
        // Photography & Videography
        "photography": .pink,
        "photographer": .pink,
        "videography": .indigo,
        "video": .indigo,
        
        // Entertainment
        "music": .blue,
        "entertainment": .blue,
        "dj": .blue,
        "band": .cyan,
        "live music": .cyan,
        
        // Flowers & Decorations
        "flowers": .green,
        "floral": .green,
        "decorations": .mint,
        "decor": .mint,
        
        // Attire & Beauty
        "attire": .indigo,
        "clothing": .indigo,
        "dress": .purple,
        "gown": .purple,
        "suit": .brown,
        "tuxedo": .brown,
        "hair": .pink,
        "makeup": .pink,
        "beauty": .pink,
        "jewelry": .yellow,
        "accessories": .yellow,
        
        // Transportation
        "transportation": .cyan,
        "transport": .cyan,
        "limo": .blue,
        "limousine": .blue,
        
        // Stationery & Paper
        "invitations": .purple,
        "stationery": .purple,
        "favors": .green,
        "gifts": .green,
        
        // Planning & Services
        "planner": .orange,
        "coordinator": .orange,
        "officiant": .blue,
        
        // Miscellaneous
        "miscellaneous": .gray,
        "other": .gray,
        "rentals": .brown,
        "rental": .brown,
        "insurance": .blue
    ]

    /// Returns the color for a given category
    static func color(for category: String) -> Color {
        colorMap[category.lowercased()] ?? .gray
    }

    // MARK: - Badge Component

    /// A reusable category badge view
    struct Badge: View {
        let category: String
        var showIcon: Bool = true
        var showLabel: Bool = true

        var body: some View {
            HStack(spacing: 6) {
                if showIcon {
                    Image(systemName: CategoryIcons.icon(for: category))
                        .font(.caption)
                        .foregroundColor(CategoryIcons.color(for: category))
                }

                if showLabel {
                    Text(category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, showLabel ? 8 : 6)
            .padding(.vertical, Spacing.xs)
            .background(CategoryIcons.color(for: category).opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Category Dot

    /// A simple colored dot for category indication
    struct Dot: View {
        let category: String
        var size: CGFloat = 6

        var body: some View {
            Circle()
                .fill(CategoryIcons.color(for: category))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Convenience Extensions

extension String {
    /// Returns the SF Symbol icon name for this category string
    var categoryIcon: String {
        CategoryIcons.icon(for: self)
    }

    /// Returns the color for this category string
    var categoryColor: Color {
        CategoryIcons.color(for: self)
    }
}
