//
//  TenantSwitchLoadingView.swift
//  I Do Blueprint
//
//  Loading overlay shown during tenant/couple switching
//

import SwiftUI

struct TenantSwitchLoadingView: View {
    let coupleName: String
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)
                    .tint(.white)
                
                // Main message
                Text("Switching to \(coupleName)...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text("Loading wedding data")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: coupleName)
    }
}

#Preview("Switching") {
    TenantSwitchLoadingView(coupleName: "JES 33 & JES 33")
}

#Preview("Long Name") {
    TenantSwitchLoadingView(coupleName: "Jessica (TEST) & Elizabeth (TEST)")
}
