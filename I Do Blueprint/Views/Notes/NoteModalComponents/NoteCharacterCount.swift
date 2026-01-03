//
//  NoteCharacterCount.swift
//  I Do Blueprint
//
//  Component for character count display
//

import SwiftUI

struct NoteCharacterCount: View {
    let currentCount: Int
    let limit: Int
    
    private var isNearLimit: Bool {
        currentCount > limit * 9 / 10
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: Spacing.xxs) {
                Text("\(currentCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isNearLimit ? .orange : SemanticColors.textSecondary)
                
                Text("/ \(limit) characters")
                    .font(.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        NoteCharacterCount(currentCount: 500, limit: 10000)
        NoteCharacterCount(currentCount: 9500, limit: 10000)
    }
    .padding()
}
