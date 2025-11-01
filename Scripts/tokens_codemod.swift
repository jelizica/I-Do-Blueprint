#!/usr/bin/swift
// tokens_codemod.swift
// Migration utility to enforce DesignSystem tokens
// - Rewrites common offenders to Spacing/AppColors
// - Default is dry-run (no writes). Use --write to apply changes.
// - Scans *.swift under project root (excluding Scripts/, Packages/, supabase/, DerivedData/, .build/)

import Foundation

struct Replacement {
    let regex: NSRegularExpression
    let replace: (NSTextCheckingResult, String) -> String?
    let description: String
}

struct Change {
    let range: NSRange
    let original: String
    let replacement: String
    let rule: String
}

let spacingMap: [String: String] = [
    "2": "Spacing.xxs",
    "4": "Spacing.xs",
    "6": "Spacing.sm",
    "8": "Spacing.sm",
    "10": "Spacing.md",
    "12": "Spacing.md",
    "14": "Spacing.md",
    "16": "Spacing.lg",
    "18": "Spacing.xl",
    "20": "Spacing.xl",
    "24": "Spacing.xxl",
    "28": "Spacing.xxxl",
    "32": "Spacing.xxxl",
    "36": "Spacing.xxxl",
    "40": "Spacing.huge",
    "48": "Spacing.huge"
]

let args = CommandLine.arguments.dropFirst()
let shouldWrite = args.contains("--write")
let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let excludedDirs = Set(["Scripts", "Packages", "supabase", ".build", "DerivedData"])

func enumerateSwiftFiles(at url: URL, handler: (URL) -> Void) {
    guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }
    for case let fileURL as URL in enumerator {
        let last = fileURL.lastPathComponent
        if excludedDirs.contains(last) {
            enumerator.skipDescendants()
            continue
        }
        if last.hasSuffix(".swift") {
            handler(fileURL)
        }
    }
}

func makeRegex(_ pattern: String) -> NSRegularExpression { try! NSRegularExpression(pattern: pattern, options: []) }

func nearestSpacingToken(for value: Double) -> String {
    // Candidate tokens in points
    let candidates: [(Double, String)] = [
        (2, "Spacing.xxs"), (4, "Spacing.xs"), (6, "Spacing.sm"), (8, "Spacing.sm"),
        (10, "Spacing.md"), (12, "Spacing.md"), (14, "Spacing.md"), (16, "Spacing.lg"),
        (18, "Spacing.xl"), (20, "Spacing.xl"), (24, "Spacing.xxl"), (28, "Spacing.xxxl"),
        (32, "Spacing.xxxl"), (36, "Spacing.xxxl"), (40, "Spacing.huge"), (48, "Spacing.huge")
    ]
    var best = candidates[0]
    var bestDelta = abs(value - best.0)
    for c in candidates.dropFirst() {
        let d = abs(value - c.0)
        if d < bestDelta { bestDelta = d; best = c }
    }
    return best.1
}

let replacements: [Replacement] = [
    // .foregroundColor(.black|.white|.gray) -> AppColors.*
    Replacement(
        regex: makeRegex(#"\.foregroundColor\s*\(\s*\.(black|white|gray)\s*\)"#),
        replace: { match, line in
            let color = (line as NSString).substring(with: match.range(at: 1))
            let token: String
            switch color {
            case "gray": token = "AppColors.textSecondary"
            case "black", "white": token = "AppColors.textPrimary"
            default: token = "AppColors.textPrimary"
            }
            let full = (line as NSString).substring(with: match.range)
            return full.replacingOccurrences(of: full, with: ".foregroundColor(\(token))")
        },
        description: "foregroundColor basic -> semantic AppColors"
    ),

    // .background(.white) -> AppColors.cardBackground
    Replacement(
        regex: makeRegex(#"\.background\s*\(\s*\.white\s*\)"#),
        replace: { match, line in
            let full = (line as NSString).substring(with: match.range)
            return full.replacingOccurrences(of: full, with: ".background(AppColors.cardBackground)")
        },
        description: ".background(.white) -> AppColors.cardBackground"
    ),

    // Color(red:..., green:..., blue:...) -> known AppColors when exact matches are recognized
    Replacement(
        regex: makeRegex(#"Color\s*\(\s*red:\s*(0\.\d+),\s*green:\s*(0\.\d+),\s*blue:\s*(0\.\d+)\s*\)"#),
        replace: { match, line in
            let ns = line as NSString
            let r = ns.substring(with: match.range(at: 1))
            let g = ns.substring(with: match.range(at: 2))
            let b = ns.substring(with: match.range(at: 3))
            let key = "\(r),\(g),\(b)"
            let map: [String: String] = [
                "0.98,0.98,0.99": "AppColors.backgroundSecondary",
                "0.95,0.96,0.96": "AppColors.borderLight",
                "0.90,0.91,0.92": "AppColors.cardBackground",
                "0.82,0.84,0.86": "AppColors.borderLight",
                "0.07,0.09,0.15": "AppColors.textPrimary",
                "0.29,0.33,0.39": "AppColors.textSecondary",
                "0.42,0.45,0.50": "AppColors.textSecondary",
                "0.60,0.62,0.65": "AppColors.textSecondary",
                "0.15,0.39,0.92": "AppColors.primary"
            ]
            if let token = map[key] {
                let full = ns.substring(with: match.range)
                return full.replacingOccurrences(of: full, with: token)
            }
            return nil
        },
        description: "Color(red:,green:,blue:) known literals -> semantic AppColors"
    ),

    // .padding(NUM) -> .padding(Spacing.*) using exact map
    Replacement(
        regex: makeRegex(#"\.padding\s*\(\s*(\d+(?:\.\d+)?)\s*\)"#),
        replace: { match, line in
            let value = (line as NSString).substring(with: match.range(at: 1))
            if let token = spacingMap[value] {
                let full = (line as NSString).substring(with: match.range)
                return full.replacingOccurrences(of: full, with: ".padding(\(token))")
            }
            return nil
        },
        description: "numeric padding -> Spacing token (exact)"
    ),

    // Fallback: .padding(NUM) -> nearest Spacing token
    Replacement(
        regex: makeRegex(#"\.padding\s*\(\s*(\d+(?:\.\d+)?)\s*\)"#),
        replace: { match, line in
            let ns = line as NSString
            let value = ns.substring(with: match.range(at: 1))
            guard let v = Double(value) else { return nil }
            let token = nearestSpacingToken(for: v)
            let full = ns.substring(with: match.range)
            return full.replacingOccurrences(of: full, with: ".padding(\(token))")
        },
        description: "numeric padding -> Spacing token (nearest)"
    ),

    // .padding(.horizontal, NUM) -> .padding(.horizontal, Spacing.*) using exact map
    Replacement(
        regex: makeRegex(#"\.padding\s*\(\s*\.(leading|trailing|top|bottom|horizontal|vertical)\s*,\s*(\d+(?:\.\d+)?)\s*\)"#),
        replace: { match, line in
            let edge = (line as NSString).substring(with: match.range(at: 1))
            let value = (line as NSString).substring(with: match.range(at: 2))
            guard let token = spacingMap[value] else { return nil }
            let full = (line as NSString).substring(with: match.range)
            return full.replacingOccurrences(of: full, with: ".padding(.\(edge), \(token))")
        },
        description: "numeric edge padding -> Spacing token (exact)"
    ),

    // Fallback: .padding(.edge, NUM) -> nearest Spacing token
    Replacement(
        regex: makeRegex(#"\.padding\s*\(\s*\.(leading|trailing|top|bottom|horizontal|vertical)\s*,\s*(\d+(?:\.\d+)?)\s*\)"#),
        replace: { match, line in
            let ns = line as NSString
            let edge = ns.substring(with: match.range(at: 1))
            let value = ns.substring(with: match.range(at: 2))
            guard let v = Double(value) else { return nil }
            let token = nearestSpacingToken(for: v)
            let full = ns.substring(with: match.range)
            return full.replacingOccurrences(of: full, with: ".padding(.\(edge), \(token))")
        },
        description: "numeric edge padding -> Spacing token (nearest)"
    ),

    // Color.white/black/gray -> AppColors.* (limited)
    Replacement(
        regex: makeRegex(#"\bColor\.(white|black|gray)\b"#),
        replace: { match, line in
            let name = (line as NSString).substring(with: match.range(at: 1))
            let token: String = (name == "gray") ? "AppColors.textSecondary" : "AppColors.textPrimary"
            let full = (line as NSString).substring(with: match.range)
            return full.replacingOccurrences(of: full, with: token)
        },
        description: "Color.white/black/gray -> semantic AppColors"
    )
]

func processFile(_ url: URL) {
    guard var text = try? String(contentsOf: url) else { return }
    var changes: [Change] = []

    // Process line-by-line to compute safe replacements with updated ranges
    let nsText = NSMutableString(string: text)
    for rule in replacements {
        let matches = rule.regex.matches(in: nsText as String, options: [], range: NSRange(location: 0, length: nsText.length))
        // Iterate in reverse to keep ranges stable when mutating
        for match in matches.reversed() {
            let full = (nsText as NSString).substring(with: match.range)
            if let replacement = rule.replace(match, nsText as String) {
                nsText.replaceCharacters(in: match.range, with: replacement)
                changes.append(Change(range: match.range, original: full, replacement: replacement, rule: rule.description))
            }
        }
    }

    // Report Color(...) rgb initializers and .font(.custom) occurrences (non-auto-fix)
    let reportOnly: [(String, String)] = [
        (#"\bColor\s*\(\s*(red|green|blue|white)\s*:"#, "literal Color initializer"),
        (#"\.font\s*\(\s*\.custom\s*\("#, ".font(.custom) usage")
    ]
    var reportFindings: [String] = []
    for (pattern, label) in reportOnly {
        let rx = makeRegex(pattern)
        let matches = rx.matches(in: nsText as String, options: [], range: NSRange(location: 0, length: nsText.length))
        if !matches.isEmpty {
            reportFindings.append("- \(label): \(matches.count) instance(s)")
        }
    }

    if changes.isEmpty && reportFindings.isEmpty { return }

    print("\n=== \(url.path) ===")
    if !changes.isEmpty {
        for c in changes {
            print("[fix] \(c.rule)\n  - \(c.original)\n  + \(c.replacement)")
        }
    }
    if !reportFindings.isEmpty {
        print("[review] Non-auto-fix candidates:\n\(reportFindings.joined(separator: "\n"))")
    }

    if shouldWrite, !changes.isEmpty {
        do {
            try (nsText as String).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            fputs("Failed to write \(url.path): \(error)\n", stderr)
        }
    }
}

enumerateSwiftFiles(at: rootURL) { file in
    processFile(file)
}

if !shouldWrite {
    print("\nDry-run complete. Re-run with --write to apply auto-fixes.\nConsider reviewing remaining 'report' findings and mapping them to AppColors/Typography manually.")
}
