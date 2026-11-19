import SwiftUI

struct ActivityDashboardView: View {
    @ObservedObject private var activityService = ActivityService.shared
    @State private var selectedMedal: Medal? = nil
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Activity")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Your pace, volume & milestones")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Session Count Badge
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                        
                        Text("\(activityService.completedSessionsCount) workouts")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.buttonBorder, lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Streak Hero Card
                        streakHeroCard
                        
                        // 2. Reaction Pace (Speed) Card
                        reactionPaceCard
                        
                        // 3. Weekly Volume Chart
                        weeklyVolumeCard
                        
                        // 4. Trophy Cabinet
                        trophyCabinetSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                }
            }
            
            // Medal Detail Overlay
            if let medal = selectedMedal {
                medalDetailModal(medal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(300)
            }
        }
    }
    
    // MARK: - 1. Streak Hero Card
    private var streakHeroCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.45, blue: 0.15), Color(red: 0.95, green: 0.25, blue: 0.20)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: Color(red: 0.95, green: 0.35, blue: 0.15).opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(activityService.currentStreak)")
                                .font(.system(size: 26, weight: .black))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("DAY STREAK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.15))
                        }
                        
                        Text(activityService.isTodayCompleted ? "Great job! Practiced today." : "Complete 1 workout to keep it alive!")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ActivityService.formatTime(activityService.todayPracticeTime))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Today's time")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            Divider()
                .background(AppTheme.buttonBorder)
            
            // 7-Day Dot Matrix
            HStack(spacing: 0) {
                ForEach(activityService.weeklyVolume) { day in
                    VStack(spacing: 6) {
                        Text(day.dayLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(day.isToday ? AppTheme.accent : AppTheme.textTertiary)
                        
                        ZStack {
                            Circle()
                                .fill(day.hasCompletedSession ? Color(red: 0.95, green: 0.40, blue: 0.15) : (day.isToday ? Color.clear : Color.black.opacity(0.04)))
                                .frame(width: 28, height: 28)
                            
                            if day.hasCompletedSession {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                            } else if day.isToday {
                                Circle()
                                    .strokeBorder(Color(red: 0.95, green: 0.40, blue: 0.15), style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 2. Reaction Pace (Speed) Card
    private var reactionPaceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.40, blue: 0.85))
                    
                    Text("REACTION PACE (SPEED)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text("sec / question")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            HStack(spacing: 12) {
                // Average Pace
                VStack(alignment: .leading, spacing: 4) {
                    Text(activityService.averagePaceOverall > 0 ? String(format: "%.1fs", activityService.averagePaceOverall) : "—")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Current Average")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Personal Best
                VStack(alignment: .leading, spacing: 4) {
                    Text(activityService.personalBestPace > 0 ? String(format: "%.1fs", activityService.personalBestPace) : "—")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(Color(red: 0.20, green: 0.70, blue: 0.45))
                    
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.15))
                        Text("Personal Best")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
            // Pace Trend Strip
            if let trend = activityService.paceTrendSummary {
                HStack(spacing: 6) {
                    Image(systemName: trend.isFaster ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend.isFaster ? Color(red: 0.20, green: 0.70, blue: 0.45) : Color(red: 0.90, green: 0.60, blue: 0.15))
                    
                    Text(trend.isFaster ? "\(String(format: "%.0f", trend.percentage))% faster than past sessions" : "\(String(format: "%.0f", trend.percentage))% slower than past sessions")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(trend.isFaster ? Color(red: 0.20, green: 0.70, blue: 0.45).opacity(0.08) : Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Text("Complete 4+ workouts to calculate your pace trend.")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 3. Weekly Volume Chart
    private var weeklyVolumeCard: some View {
        let weeklyTotalMinutes = activityService.weeklyVolume.reduce(0.0) { $0 + $1.minutes }
        let maxMinute = max(15.0, activityService.weeklyVolume.map(\.minutes).max() ?? 15.0)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                    
                    Text("WEEKLY PRACTICE TIME")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text("\(Int(round(weeklyTotalMinutes))) mins total")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            // Bar graph
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(activityService.weeklyVolume) { day in
                    VStack(spacing: 6) {
                        Text(day.minutes >= 0.5 ? "\(Int(round(day.minutes)))m" : "")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(day.isToday ? AppTheme.accent : AppTheme.textTertiary)
                            .frame(height: 12)
                        
                        GeometryReader { geo in
                            let heightRatio = CGFloat(day.minutes / maxMinute)
                            let barHeight = max(4.0, geo.size.height * heightRatio)
                            
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        day.isToday ?
                                        LinearGradient(colors: [AppTheme.accent, Color(red: 0.95, green: 0.45, blue: 0.25)], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [Color.gray.opacity(day.minutes > 0 ? 0.35 : 0.12), Color.gray.opacity(day.minutes > 0 ? 0.35 : 0.12)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(height: barHeight)
                            }
                        }
                        .frame(height: 80)
                        
                        Text(day.dayLabel)
                            .font(.system(size: 11, weight: day.isToday ? .bold : .medium))
                            .foregroundColor(day.isToday ? AppTheme.accent : AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 114)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 4. Trophy Cabinet Section
    private var trophyCabinetSection: some View {
        let unlockedCount = activityService.medals.filter(\.isUnlocked).count
        let totalCount = activityService.medals.count
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.73, blue: 0.15))
                    
                    Text("TROPHY CABINET")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text("\(unlockedCount) of \(totalCount) Unlocked")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            // 3-Column Medal Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(activityService.medals) { medal in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMedal = medal
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(medal.isUnlocked ? medal.tier.color.opacity(0.18) : Color.black.opacity(0.04))
                                    .frame(width: 52, height: 52)
                                
                                if medal.isUnlocked {
                                    Image(systemName: medal.icon)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(medal.tier.color)
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                            }
                            
                            Text(medal.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(medal.isUnlocked ? AppTheme.textPrimary : AppTheme.textTertiary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 28)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Medal Detail Modal
    private func medalDetailModal(_ medal: Medal) -> some View {
        ZStack {
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
                    
                    Text("\(medal.tier.rawValue.capitalized) • \(medal.category.rawValue)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(medal.tier.color)
                }
                
                Text(medal.description)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                if medal.isUnlocked, let date = medal.unlockedDate {
                    let formatter: DateFormatter = {
                        let df = DateFormatter()
                        df.dateStyle = .medium
                        return df
                    }()
                    Text("Earned on \(formatter.string(from: date))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.20, green: 0.70, blue: 0.45))
                } else {
                    Text("Not yet unlocked")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
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
            .frame(width: 300)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}
