//
//  TimelineWallViewV1.swift
//  I Do Blueprint
//
//  Wedding Day Timeline - Wall View
//  Masonry/card layout with glassmorphism effects for visual event planning
//

import SwiftUI

struct TimelineWallViewV1: View {
    @EnvironmentObject private var store: TimelineStoreV2

    // MARK: - State
    @State private var selectedEvent: WeddingDayEvent?
    @State private var showingEventDetail = false
    @State private var columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 3)

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Hero section with featured events
                    heroSection

                    // Masonry grid
                    masonryGrid(width: geometry.size.width)
                }
                .padding()
            }
            .background(auroraBackground)
        }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                WeddingDayEventDetailSheet(event: event, onDismiss: {
                    selectedEvent = nil
                    showingEventDetail = false
                })
            }
        }
    }

    // MARK: - Aurora Background

    private var auroraBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    TimelineColors.auroraStart,
                    TimelineColors.auroraMid,
                    TimelineColors.auroraEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated blobs (static for now)
            Circle()
                .fill(TimelineColors.blush.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100, y: -50)

            Circle()
                .fill(TimelineColors.sage.opacity(0.2))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 150, y: 200)
        }
        .ignoresSafeArea()
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            // Main event card (if exists)
            if let mainEvent = store.weddingDayEvents.first(where: { $0.isMainEvent }) {
                mainEventCard(event: mainEvent)
            }

            // Key events row
            keyEventsRow
        }
    }

    private func mainEventCard(event: WeddingDayEvent) -> some View {
        Button {
            selectedEvent = event
            showingEventDetail = true
        } label: {
            HStack(spacing: Spacing.lg) {
                // Event icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [TimelineColors.primary, TimelineColors.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("THE BIG MOMENT")
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(TimelineColors.primary)
                        .tracking(1.5)

                    Text(event.eventName)
                        .font(Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: Spacing.md) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(event.timeRangeDisplay)
                        }
                        .font(Typography.subheading)
                        .foregroundColor(AppColors.textSecondary)

                        if let venueName = event.venueName {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                Text(venueName)
                            }
                            .font(Typography.subheading)
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }

                Spacer()

                // Status indicator
                VStack(spacing: Spacing.xs) {
                    Image(systemName: event.status.icon)
                        .font(.system(size: 24))
                        .foregroundColor(event.status.color)

                    Text(event.status.displayName)
                        .font(Typography.caption)
                        .foregroundColor(event.status.color)
                }
            }
            .padding(Spacing.lg)
            .background(ceremonyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: TimelineColors.glassShadow, radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var ceremonyCardBackground: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    TimelineColors.cardCeremonyGradientStart,
                    TimelineColors.cardCeremonyGradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Glass overlay
            TimelineColors.glassBackground
                .background(.ultraThinMaterial)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [TimelineColors.primary.opacity(0.5), TimelineColors.sage.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var keyEventsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(store.keyWeddingDayEvents.filter { !$0.isMainEvent }) { event in
                    keyEventCard(event: event)
                }
            }
            .padding(.horizontal, Spacing.sm)
        }
    }

    private func keyEventCard(event: WeddingDayEvent) -> some View {
        Button {
            selectedEvent = event
            showingEventDetail = true
        } label: {
            VStack(spacing: Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(event.category.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: event.displayIcon)
                        .font(.system(size: 20))
                        .foregroundColor(event.category.color)
                }

                // Title
                Text(event.eventName)
                    .font(Typography.subheading)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                // Time
                Text(event.timeRangeDisplay)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(event.status.color)
                        .frame(width: 6, height: 6)
                    Text(event.status.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(event.status.color)
                }
            }
            .frame(width: 140)
            .padding()
            .background(glassCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Masonry Grid

    private func masonryGrid(width: CGFloat) -> some View {
        let regularEvents = store.weddingDayEvents.filter { !$0.isMainEvent && $0.status != .keyEvent }

        return LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(regularEvents) { event in
                eventCard(event: event)
            }
        }
    }

    private func eventCard(event: WeddingDayEvent) -> some View {
        Button {
            selectedEvent = event
            showingEventDetail = true
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with category
                HStack {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: event.category.icon)
                            .font(.system(size: 12))
                        Text(event.category.displayName)
                            .font(Typography.caption)
                    }
                    .foregroundColor(event.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.category.color.opacity(0.1))
                    .clipShape(Capsule())

                    Spacer()

                    // Status indicator
                    Circle()
                        .fill(event.status.color)
                        .frame(width: 8, height: 8)
                }

                // Event name
                Text(event.eventName)
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)

                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(event.timeRangeDisplay)
                        .font(Typography.caption)
                }
                .foregroundColor(AppColors.textSecondary)

                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text("\(event.calculatedDurationMinutes) min")
                        .font(Typography.caption)
                }
                .foregroundColor(AppColors.textSecondary)

                // Venue (if available)
                if let venueName = event.venueName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(venueName)
                            .font(Typography.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                // Dependency indicator
                if event.hasDependency {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 11))
                        Text("Has dependency")
                            .font(Typography.caption)
                    }
                    .foregroundColor(TimelineColors.ganttDependencyLine)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(for: event))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: TimelineColors.glassShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func cardBackground(for event: WeddingDayEvent) -> some View {
        Group {
            if event.isHighlighted {
                LinearGradient(
                    colors: [
                        TimelineColors.cardGradientStart,
                        TimelineColors.cardGradientEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.ultraThinMaterial)
            } else {
                TimelineColors.glassBackground
                    .background(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(TimelineColors.glassBorder, lineWidth: 1)
        )
    }

    private var glassCard: some View {
        TimelineColors.glassBackground
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TimelineColors.glassBorder, lineWidth: 1)
            )
    }
}

// MARK: - Additional TimelineColors Extensions

extension TimelineColors {
    /// Card gradient for ceremony/main event
    static let cardCeremonyGradientStart = BlushPink.shade100.opacity(0.5)
    /// Card gradient end for ceremony/main event
    static let cardCeremonyGradientEnd = SoftLavender.shade100.opacity(0.3)
}

// MARK: - Preview

#Preview {
    TimelineWallViewV1()
        .environmentObject(TimelineStoreV2())
        .frame(width: 1200, height: 900)
}
