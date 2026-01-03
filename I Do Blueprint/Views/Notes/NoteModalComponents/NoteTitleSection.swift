//
//  NoteTitleSection.swift
//  I Do Blueprint
//
//  Component for note title input
//

import SwiftUI

struct NoteTitleSection: View {
    @Binding var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Title")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Add title (optional)...", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SemanticColors.controlBackground)
                )
        }
    }
}

#Preview {
    NoteTitleSection(title: .constant("My Note"))
        .padding()
}
