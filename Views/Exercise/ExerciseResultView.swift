import SwiftUI

struct ExerciseResultView: View {
    let summary: QuizSessionResult
    var onRetrySameQuestions: () -> Void
    var onChangeConfig: () -> Void
    var onFinish: () -> Void
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Hasil Latihan")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 36)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 14)
                .background(AppTheme.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Main Score Card
                        VStack(spacing: 14) {
                            Text("SKOR AKHIR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.6)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(summary.formattedScore)
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundColor(summary.rawScore >= 70 ? Color(hex: 0x34C759) : AppTheme.accent)
                                
                                Text("/ 100")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Divider()
                                .background(AppTheme.cardBorder)
                                .padding(.horizontal, 10)
                            
                            // Stats Row
                            HStack {
                                VStack(spacing: 4) {
                                    Text("BENAR")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("\(summary.correctCount) / \(summary.totalQuestions)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Rectangle()
                                    .fill(AppTheme.cardBorder)
                                    .frame(width: 1, height: 28)
                                
                                VStack(spacing: 4) {
                                    Text("TOTAL WAKTU")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(String(format: "%.1fs", summary.totalTime))
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Rectangle()
                                    .fill(AppTheme.cardBorder)
                                    .frame(width: 1, height: 28)
                                
                                VStack(spacing: 4) {
                                    Text("RATA-RATA")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(String(format: "%.1fs/soal", summary.averageTime))
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                        
                        // 2. Question Breakdown List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DETAIL PERTANYAAN")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            VStack(spacing: 10) {
                                ForEach(summary.results) { res in
                                    resultRow(res: res)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Bottom 3 Action Buttons (Pinned)
                VStack(spacing: 10) {
                    // 1. Primary: Ulangi Soal yang Sama
                    Button(action: onRetrySameQuestions) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .bold))
                            Text("Ulangi Soal yang Sama")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: AppTheme.accent.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    
                    // 2. Secondary: Ubah Pengaturan Kuis
                    Button(action: onChangeConfig) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Ubah Pengaturan Kuis")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // 3. Tertiary: Selesai / Kembali ke Daftar Kata
                    Button(action: onFinish) {
                        Text("← Selesai (Kembali ke Daftar Kata)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(AppTheme.background)
            }
        }
    }
    
    // MARK: - Result Row
    @ViewBuilder
    private func resultRow(res: QuestionResult) -> some View {
        let isSlowest = (res.id == summary.slowestResultId)
        let target = res.question.targetWord
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Number & Status
                HStack(spacing: 6) {
                    Text("#\(res.question.questionNumber)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: res.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(res.isCorrect ? "Benar" : "Salah")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(res.isCorrect ? Color(hex: 0x28A745) : Color(hex: 0xDC3545))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(res.isCorrect ? Color(hex: 0xE8F5E9) : Color(hex: 0xFFEBEE))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Time Badge
                HStack(spacing: 4) {
                    Image(systemName: isSlowest ? "exclamationmark.triangle.fill" : "stopwatch")
                        .font(.system(size: 10))
                    Text(String(format: "%.1fs", res.timeSpent))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    
                    if isSlowest && summary.results.count > 1 {
                        Text("(Paling Lama)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundColor(isSlowest && summary.results.count > 1 ? Color(hex: 0xE65100) : AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isSlowest && summary.results.count > 1 ? Color(hex: 0xFFF3E0) : AppTheme.inputBackground)
                .clipShape(Capsule())
            }
            
            // Question Target Word
            HStack(spacing: 8) {
                Text(target.kanji.isEmpty ? target.kana : target.kanji)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                if !target.kanji.isEmpty && target.kanji != target.kana {
                    Text(target.kana)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Text("• \(target.meaningEn)")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            
            // If incorrect, show user choice vs correct answer
            if !res.isCorrect {
                VStack(alignment: .leading, spacing: 3) {
                    if res.selectedIndex < res.question.options.count {
                        let chosen = res.question.options[res.selectedIndex]
                        HStack(spacing: 4) {
                            Text("Jawaban Anda:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: 0xDC3545))
                            Text(chosen.kanji.isEmpty ? chosen.kana : chosen.kanji)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: 0xDC3545))
                            Text("(\(chosen.meaningEn))")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0xDC3545).opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("Kunci Jawaban:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: 0x28A745))
                        Text(target.kanji.isEmpty ? target.kana : target.kanji)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: 0x28A745))
                        Text("(\(target.meaningEn))")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0x28A745).opacity(0.8))
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(res.isCorrect ? Color(hex: 0x28A745).opacity(0.3) : Color(hex: 0xDC3545).opacity(0.3), lineWidth: 1)
        )
    }
}
