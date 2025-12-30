//
//  LoggingSettingsView.swift
//  I Do Blueprint
//
//  Settings view for managing logging configuration
//

import SwiftUI

struct LoggingSettingsView: View {
    @StateObject private var config = LoggingConfiguration.shared
    @State private var showingPresetSheet = false
    
    var body: some View {
        Form {
            Section {
                Picker("Global Log Level", selection: $config.globalLogLevel) {
                    ForEach([LogLevel.debug, .info, .warning, .error, .fault], id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                
                Toggle("Include Source Location", isOn: $config.includeSourceLocation)
                    .help("Show file, function, and line number in logs")
                
                Toggle("Enable Performance Metrics", isOn: $config.enablePerformanceMetrics)
                    .help("Log performance metrics for operations")
            } header: {
                Text("General Settings")
            } footer: {
                Text("Global log level applies to all categories unless overridden below.")
            }
            
            Section {
                Button("Apply Production Preset") {
                    config.applyProductionPreset()
                }
                .help("Optimized for production: Info level, reduced cache/network verbosity")
                
                Button("Apply Development Preset") {
                    config.applyDevelopmentPreset()
                }
                .help("Full debug logging with source locations")
                
                Button("Apply Debugging Preset") {
                    config.applyDebuggingPreset()
                }
                .help("Maximum verbosity for troubleshooting")
                
                Button("Apply Minimal Preset") {
                    config.applyMinimalPreset()
                }
                .help("Errors only, minimal overhead")
            } header: {
                Text("Presets")
            }
            
            Section {
                ForEach([LogCategory.api, .repository, .database, .network, .cache, .ui, .auth, .storage, .analytics, .export, .general], id: \.self) { category in
                    CategoryConfigRow(category: category, config: config)
                }
            } header: {
                Text("Per-Category Configuration")
            } footer: {
                Text("Override log level and sampling rate for specific categories. Empty values use global settings.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Logging Configuration")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reset All") {
                    config.applyDevelopmentPreset()
                }
            }
        }
    }
}

struct CategoryConfigRow: View {
    let category: LogCategory
    @ObservedObject var config: LoggingConfiguration
    
    @State private var showingLevelPicker = false
    @State private var showingSamplingPicker = false
    
    private var effectiveLevel: LogLevel {
        config.effectiveLogLevel(for: category)
    }
    
    private var samplingRate: Double? {
        config.samplingRates[category]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.displayName)
                    .font(.headline)
                
                Spacer()
                
                // Log Level
                Menu {
                    Button("Use Global (\(config.globalLogLevel.displayName))") {
                        config.removeLogLevel(for: category)
                    }
                    
                    Divider()
                    
                    ForEach([LogLevel.debug, .info, .warning, .error, .fault], id: \.self) { level in
                        Button(level.displayName) {
                            config.setLogLevel(level, for: category)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(effectiveLevel.displayName)
                        if config.categoryLevels[category] != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    .font(.subheadline)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 100)
            }
            
            // Sampling Rate
            HStack {
                Text("Sampling:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let rate = samplingRate {
                    Text("\(Int(rate * 100))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Button(action: {
                        config.removeSamplingRate(for: category)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("100% (No sampling)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("No Sampling (100%)") {
                        config.removeSamplingRate(for: category)
                    }
                    
                    Divider()
                    
                    ForEach([0.1, 0.25, 0.5, 0.75], id: \.self) { rate in
                        Button("\(Int(rate * 100))%") {
                            config.setSamplingRate(rate, for: category)
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        LoggingSettingsView()
    }
}
