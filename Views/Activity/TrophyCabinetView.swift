import SwiftUI

struct TrophyCabinetView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var activityService = ActivityService.shared
    
    @State private var selectedCategory: MedalCategory = .all
    @State private var selectedStatusFilter: MedalStatusFilter = .all
    @State private var selectedMedal: Medal? = nil
    
    enum MedalStatusFilter: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"
    }
    
    // MARK: - Filtered Medals
    private var filteredMedals: [Medal] {
        var list = activityService.medals
        
        if selectedCategory != .all {
            list = list.filter { $0.category == selectedCategory }
        }
        
        switch selectedStatusFilter {
        case .all:
            break
        case .unlocked:
            list = list.filter(\.isUnlocked)
        case .locked:
            list = list.filter { !$0.isUnlocked }
        }
        
        return list
    }
    
    private var totalUnlocked: Int {
        activityService.medals.filter(\.isUnlocked).count
    }
    
    private var overallPercentage: Int {
        let total = activityService.medals.count
        guard total > 0 else { return 0 }
        return Int(round((Double(totalUnlocked) / Double(total)) * 100.0))
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Overall Progress & Tier Breakdown Hero Card
                        heroProgressCard
                        
                        // Category Pills
                        categoryFilterBar
                        
                        // Status Filter (All / Unlocked / Locked)
                        statusFilterBar
                        
                        // Medals Grid
                        medalsGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 60)
                }
            }
            
            // In-Cabinet Medal Detail Modal
            if let medal = selectedMedal {
                medalDetailModal(medal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(300)
            }
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isPresented = false
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(AppTheme.accent)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Trophy Cabinet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(totalUnlocked) of \(activityService.medals.count) Unlocked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Invisible balancing element for exact center alignment
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("Back")
                    .font(.system(size: 18, weight: .semibold))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        #if os(macOS)
        .padding(.top, 36)
        #else
        .padding(.top, 16)
        #endif
        .padding(.bottom, 14)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.buttonBorder),
            alignment: .bottom
        )
    }
    
    // MARK: - Hero Progress Card
    private var heroProgressCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.78, blue: 0.25), Color(red: 0.92, green: 0.60, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.92, green: 0.60, blue: 0.10).opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("\(totalUnlocked) / \(activityService.medals.count)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("(\(overallPercentage)%)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                    }
                    
                    Text("Total Master Catalog Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            
            // Overall Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 7)
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, Color(red: 0.95, green: 0.70, blue: 0.20)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6.0, geo.size.width * CGFloat(Double(totalUnlocked) / Double(max(1, activityService.medals.count)))), height: 7)
                }
            }
            .frame(height: 7)
            
            Divider()
                .background(AppTheme.buttonBorder)
            
            // Tier Breakdown Chips
            HStack(spacing: 6) {
                ForEach(activityService.medalTierBreakdown, id: \.tier.rawValue) { item in
                    VStack(spacing: 2) {
                        Text("\(item.unlocked)/\(item.total)")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(item.unlocked > 0 ? item.tier.color : AppTheme.textTertiary)
                        
                        Text(item.tier.title)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(item.tier.color.opacity(item.unlocked > 0 ? 0.12 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Category Filter Bar
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(MedalCategory.allCases, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    let count = cat == .all ? activityService.medals.count : activityService.medals.filter { $0.category == cat }.count
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .bold))
                            Text("(\(count))")
                                .font(.system(size: 10, weight: .medium))
                                .opacity(0.8)
                        }
                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? AppTheme.accent : Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : AppTheme.buttonBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Status Filter Bar (All / Unlocked / Locked)
    private var statusFilterBar: some View {
        HStack(spacing: 6) {
            ForEach(MedalStatusFilter.allCases, id: \.self) { status in
                let isSelected = selectedStatusFilter == status
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedStatusFilter = status
                    }
                }) {
                    Text(status.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isSelected ? AppTheme.accentLight.opacity(0.4) : Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? AppTheme.accent.opacity(0.3) : AppTheme.buttonBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
            
            Text("\(filteredMedals.count) trophies")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textTertiary)
        }
    }
    
    // MARK: - Medals Grid
    private var medalsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(filteredMedals) { medal in
                let progressInfo = activityService.medalProgress(for: medal)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMedal = medal
                    }
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(medal.isUnlocked ? medal.tier.color.opacity(0.18) : Color.black.opacity(0.04))
                                .frame(width: 48, height: 48)
                            
                            if medal.isUnlocked {
                                Image(systemName: medal.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(medal.tier.color)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                        
                        Text(medal.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(medal.isUnlocked ? AppTheme.textPrimary : AppTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 28)
                        
                        // Tier pill
                        Text(medal.tier.title)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(medal.isUnlocked ? medal.tier.color : AppTheme.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(medal.isUnlocked ? medal.tier.color.opacity(0.12) : AppTheme.inputBackground)
                            .clipShape(Capsule())
                        
                        // Progress bar or Unlocked Tag
                        if medal.isUnlocked {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .black))
                                Text("Earned")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(Color(red: 0.20, green: 0.70, blue: 0.45))
                        } else {
                            if progressInfo.progressRatio > 0.0 {
                                VStack(spacing: 2) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .fill(Color.black.opacity(0.06))
                                                .frame(height: 4)
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .fill(medal.tier.color)
                                                .frame(width: max(2.0, geo.size.width * CGFloat(progressInfo.progressRatio)), height: 4)
                                        }
                                    }
                                    .frame(height: 4)
                                    
                                    Text("\(progressInfo.currentFormatted) / \(progressInfo.targetFormatted)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(AppTheme.textTertiary)
                                        .lineLimit(1)
                                }
                            } else {
                                Text("Locked")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(medal.isUnlocked ? medal.tier.color.opacity(0.3) : AppTheme.buttonBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Medal Detail Modal
    private func medalDetailModal(_ medal: Medal) -> some View {
        let progressInfo = activityService.medalProgress(for: medal)
        
        return ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMedal = nil
                    }
                }
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(medal.isUnlocked ? medal.tier.color.opacity(0.2) : Color.gray.opacity(0.15))
                        .frame(width: 76, height: 76)
                    
                    Image(systemName: medal.isUnlocked ? medal.icon : "lock.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(medal.isUnlocked ? medal.tier.color : AppTheme.textSecondary)
                }
                .padding(.top, 8)
                
                VStack(spacing: 4) {
                    Text(medal.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("\(medal.tier.title) • \(medal.category.rawValue) • \(medal.axis.rawValue)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(medal.tier.color)
                }
                
                Text(medal.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                // Progress status
                if medal.isUnlocked, let date = medal.unlockedDate {
                    let formatter: DateFormatter = {
                        let df = DateFormatter()
                        df.dateStyle = .medium
                        return df
                    }()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Earned on \(formatter.string(from: date))")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.20, green: 0.70, blue: 0.45))
                } else {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Current Progress:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(progressInfo.progressRatio > 0.0 ? "\(progressInfo.currentFormatted) of \(progressInfo.targetFormatted) (\(progressInfo.progressPercentageText))" : "Not yet started")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(progressInfo.progressRatio > 0.0 ? AppTheme.accent : AppTheme.textTertiary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.black.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(medal.tier.color)
                                    .frame(width: max(2.0, geo.size.width * CGFloat(progressInfo.progressRatio)), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(12)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMedal = nil
                    }
                }) {
                    Text("Close")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(24)
            .frame(width: 310)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}
