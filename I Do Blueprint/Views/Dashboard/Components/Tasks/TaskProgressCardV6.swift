//
//  TaskProgressCardV6.swift
//  I Do Blueprint
//
//  Native macOS "Wow Factor" version with premium visual design:
//  - SwiftUI Material backgrounds for vibrancy
//  - Gradient border strokes for depth
//  - Multi-layer macOS-native shadows
//  - Hover elevation with spring animations
//  - Staggered appearance animations
//  - System colors that adapt to light/dark mode
//

import SwiftUI

struct TaskProgressCardV6: View {
    @ObservedObject var store: TaskStoreV2
    let userTimezone: TimeZone
    
    // Animation state
    @State private var hasAppeared = false
    @State private var isHovered = false

    var body: some View {
        let remainingTasks = store.tasks.filter { $0.status != .completed }.count
        let completedTasks = store.tasks.filter { $0.status == .completed }.count
        let totalTasks = store.tasks.count
        let completionProgress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // MARK: - Header Section
            HStack(spacing: Spacing.md) {
                // Native icon badge
                NativeIconBadge(
                    systemName: "checklist",
                    color: AppColors.Task.inProgress,
                    size: 44
                )
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Task Manager")
                        .font(Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(nsColor: .labelColor))

                    Text("\(remainingTasks) tasks remaining")
                        .font(Typography.caption)
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                
                Spacer()
                
                // Completion badge
                if totalTasks > 0 {
                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(completionProgress * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        SemanticColors.success,
                                        SemanticColors.success.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Complete")
                            .font(Typography.caption2)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.success.opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : -10)
            
            // Native gradient divider
            NativeDividerStyle(opacity: 0.4)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
            
            // MARK: - Progress Bar Section
            if totalTasks > 0 {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.Task.inProgress, AppColors.Task.inProgress.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("Overall Progress")
                            .font(Typography.caption)
                            .foregroundColor(Color(nsColor: .labelColor))

                        Spacer()

                        Text("\(completedTasks) of \(totalTasks)")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundColor(Color(nsColor: .labelColor))
                    }

                    // Native progress bar with inner shadow and glow
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track with inner shadow effect
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(nsColor: .separatorColor).opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                                )
                                .frame(height: 10)

                            // Progress fill with gradient and glow
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.Task.inProgress, AppColors.Task.inProgress.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geometry.size.width * completionProgress, 10), height: 10)
                                .shadow(color: AppColors.Task.inProgress.opacity(0.4), radius: 4, x: 0, y: 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionProgress)
                        }
                    }
                    .frame(height: 10)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)
                .padding(.bottom, Spacing.sm)
            }
            
            // MARK: - Recent Tasks Section
            if !store.tasks.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Section divider
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)

                    // Section header
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.Task.inProgress)
                        
                        Text("Recent Tasks")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundColor(Color(nsColor: .labelColor))
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)

                    // Task rows
                    ForEach(Array(store.tasks.prefix(5).enumerated()), id: \.element.id) { index, task in
                        NativeTaskRow(task: task, userTimezone: userTimezone)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.5 + Double(index) * 0.05), value: hasAppeared)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: Spacing.md) {
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                    
                    VStack(spacing: Spacing.sm) {
                        // Success icon with gradient
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            SemanticColors.success.opacity(0.15),
                                            SemanticColors.success.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            SemanticColors.success,
                                            SemanticColors.success.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: SemanticColors.success.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Text("All tasks completed!")
                            .font(Typography.caption)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)
            }
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 347)
        // Native macOS card styling
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.4 : 0.3),
                            Color.white.opacity(isHovered ? 0.15 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        // Multi-layer macOS shadows
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 0.5)
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.05), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .shadow(color: Color.black.opacity(isHovered ? 0.04 : 0.02), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
        // Hover interaction
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Native Task Row Component

private struct NativeTaskRow: View {
    let task: WeddingTask
    let userTimezone: TimeZone
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status icon with gradient
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    task.status == .completed
                        ? LinearGradient(
                            colors: [SemanticColors.success, SemanticColors.success.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color(nsColor: .secondaryLabelColor), Color(nsColor: .secondaryLabelColor).opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )

            Text(task.taskName)
                .font(Typography.caption)
                .foregroundColor(task.status == .completed ? Color(nsColor: .secondaryLabelColor) : Color(nsColor: .labelColor))
                .strikethrough(task.status == .completed)
                .lineLimit(1)

            Spacer()

            if let dueDate = task.dueDate {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: dueDateIcon(dueDate))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(dueDateColor(dueDate))
                    
                    Text(dueDateText(dueDate))
                        .font(Typography.caption2)
                        .foregroundColor(dueDateColor(dueDate))
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(dueDateColor(dueDate).opacity(0.1))
                )
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func dueDateText(_ date: Date) -> String {
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let days = DateFormatting.daysBetween(from: now, to: date, in: userTimezone)
            if days > 0 {
                return "\(days)d"
            } else {
                return "Overdue"
            }
        }
    }
    
    private func dueDateIcon(_ date: Date) -> String {
        let days = DateFormatting.daysBetween(from: Date(), to: date, in: userTimezone)
        
        if days < 0 {
            return "exclamationmark.triangle.fill"
        } else if days <= 1 {
            return "clock.fill"
        } else {
            return "calendar"
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        let days = DateFormatting.daysBetween(from: Date(), to: date, in: userTimezone)

        if days < 0 {
            return SemanticColors.error
        } else if days <= 1 {
            return SemanticColors.warning
        } else {
            return Color(nsColor: .secondaryLabelColor)
        }
    }
}

// MARK: - Preview

#Preview("Task Progress V6 - Light") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        TaskProgressCardV6(
            store: TaskStoreV2(),
            userTimezone: .current
        )
        .frame(width: 400, height: 400)
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Task Progress V6 - Dark") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        TaskProgressCardV6(
            store: TaskStoreV2(),
            userTimezone: .current
        )
        .frame(width: 400, height: 400)
        .padding()
    }
    .preferredColorScheme(.dark)
}
