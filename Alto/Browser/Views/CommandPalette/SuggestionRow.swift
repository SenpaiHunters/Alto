//
//  SuggestionRow.swift
//  Alto
//
//  Created by Hunor Zoltáni on 19.06.2025.
//

import SwiftUI
import OpenADK

struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let isSelected: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: suggestion.type.rawValue)
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 16, height: 16)
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .allowsHitTesting(false)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Group {
                if isHovered  || isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.05))
                        .padding(.horizontal, 4)
                } else {
                    Color.clear
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

