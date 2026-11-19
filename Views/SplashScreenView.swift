import SwiftUI

struct SplashScreenView: View {
    @Binding var isShowing: Bool
    
    @State private var mascotScale: CGFloat = 0.7
    @State private var mascotOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 16
    @State private var mascotFloatingOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Warm aesthetic Japanese cream background
            AppTheme.background
                .ignoresSafeArea()
            
            // Subtle ambient warm glow behind mascot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xFCE2A7).opacity(0.45),
                            Color(hex: 0xFAF7F2).opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(mascotScale)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Mascot Image with spring bounce
                Image("OnigiriMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 215, height: 215)
                    .offset(y: mascotFloatingOffset)
                    .shadow(color: Color.black.opacity(0.09), radius: 20, x: 0, y: 12)
                    .scaleEffect(mascotScale)
                    .opacity(mascotOpacity)
                
                // Brand Title & Tagline
                VStack(spacing: 8) {
                    Text("がんばって")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("G A N B A T T E")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accent)
                        .tracking(3.5)
                    
                    Text("Learn Japanese with Joy")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top, 2)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissSplash()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 1. Pop-in mascot with spring
        withAnimation(.spring(response: 0.65, dampingFraction: 0.68, blendDuration: 0)) {
            mascotScale = 1.0
            mascotOpacity = 1.0
        }
        
        // 2. Fade in typography smoothly
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        // 3. Gentle floating motion
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.65)) {
            mascotFloatingOffset = -6
        }
        
        // 4. Auto transition after ~2.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dismissSplash()
        }
    }
    
    private func dismissSplash() {
        guard isShowing else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            isShowing = false
        }
    }
}
