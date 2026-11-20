import SwiftUI

struct ActivityDashboardView: View {
    @ObservedObject private var activityService = ActivityService.shared
    @State private var selectedMedal: Medal? = nil
    @State private var selectedDiagnosticCategory: ExerciseCategory = .kotoba
    @State private var isShowingTrophyCabinet: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Streak Hero Card (Strictly Hardcore)
                        streakHeroCard
                        
                        // 2. Reaction Pace & Speed Card (Benchmark-Aware)
                        reactionPaceCard
                        
                        // 3. Weakness Spotlight & Diagnostic Radar (NEW)
                        diagnosticRadarCard
                        
                        // 4. Level Mastery Carousel (N5 - N1 Horizontal Swipe)
                        levelMasteryCarousel
                        
                        // 5. Weekly Practice Volume Bar Chart
                        weeklyVolumeCard
                        
                        // 6. Trophy Highlights (Dashboard Showcase)
                        trophyHighlightsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                }
            }
            
            // Dedicated Full Trophy Cabinet
            if isShowingTrophyCabinet {
                TrophyCabinetView(isPresented: $isShowingTrophyCabinet)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                    .zIndex(200)
            }
            
            // Medal Detail Overlay
            if let medal = selectedMedal {
                medalDetailModal(medal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(300)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
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
    
    // MARK: - 2. Reaction Pace & Speed Card (Benchmark-Aware)
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
                
                Text(activityService.nativeBenchmarkBracketTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accentLight.opacity(0.4))
                    .clipShape(Capsule())
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
    
    // MARK: - 3. Weakness Spotlight & Diagnostic Radar
    private var diagnosticRadarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                    
                    Text("WEAKNESS SPOTLIGHT & RADAR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // Category Picker
                HStack(spacing: 4) {
                    Button(action: { selectedDiagnosticCategory = .kotoba }) {
                        Text("Kotoba")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(selectedDiagnosticCategory == .kotoba ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(selectedDiagnosticCategory == .kotoba ? AppTheme.accent : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { selectedDiagnosticCategory = .kana }) {
                        Text("Kana")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(selectedDiagnosticCategory == .kana ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(selectedDiagnosticCategory == .kana ? AppTheme.accent : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(2)
                .background(AppTheme.inputBackground)
                .clipShape(Capsule())
            }
            
            if selectedDiagnosticCategory == .kotoba {
                kotobaDiagnosticView
            } else {
                kanaDiagnosticView
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
    
    private var kotobaDiagnosticView: some View {
        VStack(spacing: 12) {
            let diags = activityService.wordTypeDiagnostics()
            
            HStack(spacing: 8) {
                ForEach(diags) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.type.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        if item.totalQuestions > 0 {
                            HStack(spacing: 4) {
                                Text("\(Int(round(item.accuracyPercentage)))%")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(item.accuracyPercentage >= 90 ? Color(red: 0.20, green: 0.70, blue: 0.45) : (item.accuracyPercentage >= 75 ? Color.orange : Color(hex: 0xDC3545)))
                                
                                Text(item.averagePace > 0 ? String(format: "• %.1fs", item.averagePace) : "")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Text("\(item.totalQuestions) words")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textTertiary)
                        } else {
                            Text("No data yet")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textTertiary)
                                .frame(height: 30)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            
            // Automated Recommendation Strip with 1-Tap Practice Launcher
            if let weakType = activityService.identifiedWeakWordType {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0xE65100))
                    
                    Text("Focus Area: \(weakType.rawValue) needs practice.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        var cfg = QuizConfig.load()
                        cfg.type = weakType
                        cfg.save()
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ganbatte_shortcut_to_exercise"),
                            object: nil,
                            userInfo: ["category": "Kotoba", "type": weakType.rawValue]
                        )
                        UserDefaults.standard.set(AppTab.exercise.rawValue, forKey: "ganbatte_active_main_tab")
                    }) {
                        Text("Train \(weakType.rawValue) ➔")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color(red: 0.98, green: 0.92, blue: 0.82))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
    
    private var kanaDiagnosticView: some View {
        VStack(spacing: 12) {
            let diags = activityService.kanaScriptDiagnostics()
            
            HStack(spacing: 10) {
                // Hiragana Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Hiragana")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Text("あ")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(AppTheme.accent)
                    }
                    
                    if diags.hiragana.totalQuestions > 0 {
                        Text("\(Int(round(diags.hiragana.accuracyPercentage)))% Accuracy")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(diags.hiragana.accuracyPercentage >= 90 ? Color(red: 0.20, green: 0.70, blue: 0.45) : Color.orange)
                        
                        Text(String(format: "Avg pace: %.1fs", diags.hiragana.averagePace))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("No sessions yet")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Katakana Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Katakana")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Text("ア")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(Color(red: 0.25, green: 0.48, blue: 0.88))
                    }
                    
                    if diags.katakana.totalQuestions > 0 {
                        Text("\(Int(round(diags.katakana.accuracyPercentage)))% Accuracy")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(diags.katakana.accuracyPercentage >= 90 ? Color(red: 0.20, green: 0.70, blue: 0.45) : Color.orange)
                        
                        Text(String(format: "Avg pace: %.1fs", diags.katakana.averagePace))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("No sessions yet")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            if activityService.identifiedWeakKanaScript == .katakana {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0xE65100))
                    
                    Text("Katakana hesitation detected.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        var kCfg = KanaQuizConfig.load()
                        kCfg.kanaType = .katakana
                        kCfg.save()
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ganbatte_shortcut_to_exercise"),
                            object: nil,
                            userInfo: ["category": "Kana", "kanaType": "Katakana"]
                        )
                        UserDefaults.standard.set(AppTab.exercise.rawValue, forKey: "ganbatte_active_main_tab")
                    }) {
                        Text("Practice Katakana ➔")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color(red: 0.98, green: 0.92, blue: 0.82))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
    
    // MARK: - 4. Level Mastery Carousel (N5 - N1 Horizontal Swipe)
    private var levelMasteryCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.15))
                    
                    Text("LEVEL MASTERY QUEST")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text("Swipe N5 ➔ N1")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activityService.allLevelsMastery) { levelInfo in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(levelInfo.level.rawValue)
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(round(levelInfo.coveragePercentage)))% Cleared")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(levelInfo.coveragePercentage > 0 ? Color(red: 0.20, green: 0.70, blue: 0.45) : AppTheme.textTertiary)
                            }
                            
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.black.opacity(0.06))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(AppTheme.accent)
                                        .frame(width: max(4.0, geo.size.width * CGFloat(levelInfo.coveragePercentage / 100.0)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            HStack {
                                Text("\(levelInfo.uniqueCorrectWords) of \(levelInfo.totalWords) words")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                            }
                            
                            // Micro-step Badges
                            HStack(spacing: 6) {
                                microBadge("Noun", isDone: levelInfo.nounMastered)
                                microBadge("Adj", isDone: levelInfo.adjMastered)
                                microBadge("Verb", isDone: levelInfo.verbMastered)
                                microBadge("All", isDone: levelInfo.allMastered)
                            }
                            .padding(.top, 2)
                        }
                        .frame(width: 230)
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private func microBadge(_ label: String, isDone: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: isDone ? "checkmark" : "lock.fill")
                .font(.system(size: 8, weight: .bold))
            Text(label)
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(isDone ? Color(red: 0.20, green: 0.70, blue: 0.45) : AppTheme.textTertiary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isDone ? Color(red: 0.20, green: 0.70, blue: 0.45).opacity(0.12) : AppTheme.inputBackground)
        .clipShape(Capsule())
    }
    
    // MARK: - 5. Weekly Volume Chart
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
    
    // MARK: - 6. Trophy Highlights (Dashboard Showcase)
    private var trophyHighlightsCard: some View {
        let unlockedCount = activityService.medals.filter(\.isUnlocked).count
        let totalCount = activityService.medals.count
        let recentUnlocked = Array(activityService.recentUnlockedMedals.prefix(3))
        let nextToUnlock = activityService.nextToUnlockMedals
        
        return VStack(alignment: .leading, spacing: 14) {
            // Card Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.73, blue: 0.15).opacity(0.18))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.73, blue: 0.15))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TROPHY CABINET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("\(unlockedCount) of \(totalCount) Unlocked")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                
                Spacer()
                
                // View All Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isShowingTrophyCabinet = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accentLight.opacity(0.35))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Sub-section A: Recently Earned
            VStack(alignment: .leading, spacing: 8) {
                Text("RECENTLY EARNED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.textTertiary)
                
                if !recentUnlocked.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(recentUnlocked) { medal in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedMedal = medal
                                }
                            }) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(medal.tier.color.opacity(0.18))
                                            .frame(width: 34, height: 34)
                                        
                                        Image(systemName: medal.icon)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(medal.tier.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(medal.title)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .lineLimit(1)
                                        
                                        Text(medal.tier.title)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(medal.tier.color)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(AppTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.73, blue: 0.15))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start your collection!")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Earn medals by scoring ≥90%, keeping streaks & mastering levels.")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(10)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            
            // Sub-section B: Next to Unlock (Gamified Progress)
            if !nextToUnlock.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("NEXT TO UNLOCK")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textTertiary)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(nextToUnlock) { info in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedMedal = info.medal
                                }
                            }) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(info.medal.tier.color.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: info.medal.icon)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(info.medal.tier.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(info.medal.title)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                            
                                            Text("• \(info.medal.tier.title)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(info.medal.tier.color)
                                            
                                            Spacer()
                                            
                                            Text("\(info.currentFormatted) / \(info.targetFormatted)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(AppTheme.accent)
                                        }
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                    .fill(Color.black.opacity(0.06))
                                                    .frame(height: 5)
                                                
                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [info.medal.tier.color, AppTheme.accent],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: max(3.0, geo.size.width * CGFloat(info.progressRatio)), height: 5)
                                            }
                                        }
                                        .frame(height: 5)
                                    }
                                }
                                .padding(10)
                                .background(AppTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                    
                    Text("\(medal.tier.title) • \(medal.category.rawValue) • \(medal.axis.rawValue)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(medal.tier.color)
                }
                
                Text(medal.description)
                    .font(.system(size: 13))
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
