import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case learn = "learn"
    case exercise = "exercise"
    case activity = "activity"
    case reminders = "reminders"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .learn: return "Learn"
        case .exercise: return "Exercise"
        case .activity: return "Activity"
        case .reminders: return "Reminders"
        }
    }
    
    var iconName: String {
        switch self {
        case .learn: return "books.vertical.fill"
        case .exercise: return "bolt.fill"
        case .activity: return "flame.fill"
        case .reminders: return "bell.fill"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "learn", "words", "kana":
            self = .learn
        case "exercise":
            self = .exercise
        case "activity":
            self = .activity
        case "reminders":
            self = .reminders
        default:
            return nil
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
