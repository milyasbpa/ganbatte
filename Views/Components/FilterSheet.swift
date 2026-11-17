import SwiftUI

struct DifficultyModalView: View {
    @Binding var selectedLevel: JLPTLevel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                Text("DIFFICULTY")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                VStack(spacing: 0) {
                    ForEach(JLPTLevel.allCases) { level in
                        Button(action: {
                            selectedLevel = level
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }) {
                            HStack {
                                Text(level.title)
                                    .font(.system(size: 16, weight: selectedLevel == level ? .semibold : .regular))
                                    .foregroundColor(selectedLevel == level ? AppTheme.accent : AppTheme.textPrimary)
                                
                                if let subtitle = level.subtitle {
                                    Text(subtitle)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer(minLength: 0)
                                
                                if selectedLevel == level {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(selectedLevel == level ? AppTheme.accentLight.opacity(0.6) : Color.clear)
                            .contentShape(Rectangle()) // Ensures entire row width is tappable
                        }
                        .buttonStyle(.plain)
                        
                        if level != JLPTLevel.allCases.last {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(maxWidth: 340)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 10)
            .padding(.horizontal, 30)
        }
    }
}

struct TypeModalView: View {
    @Binding var selectedType: WordType
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                Text("TYPE")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                VStack(spacing: 0) {
                    ForEach(WordType.allCases) { type in
                        Button(action: {
                            selectedType = type
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }) {
                            HStack {
                                Text(type.title)
                                    .font(.system(size: 16, weight: selectedType == type ? .semibold : .regular))
                                    .foregroundColor(selectedType == type ? AppTheme.accent : AppTheme.textPrimary)
                                
                                Spacer(minLength: 0)
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(selectedType == type ? AppTheme.accentLight.opacity(0.6) : Color.clear)
                            .contentShape(Rectangle()) // Ensures entire row width is tappable
                        }
                        .buttonStyle(.plain)
                        
                        if type != WordType.allCases.last {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(maxWidth: 320)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 10)
            .padding(.horizontal, 30)
        }
    }
}
