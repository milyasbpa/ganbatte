import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case words = "words"
    case kana = "kana"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .words: return "Words"
        case .kana: return "Kana"
        }
    }
    
    var iconName: String {
        switch self {
        case .words: return "book.closed.fill"
        case .kana: return "character.bubble.fill"
        }
    }
}

struct BottomNavBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                        
                        Text(tab.title)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(AppTheme.buttonBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
}
