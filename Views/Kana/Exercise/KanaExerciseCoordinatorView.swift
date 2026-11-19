import SwiftUI

enum KanaExerciseFlowState {
    case config
    case quiz
    case result
}

struct KanaExerciseCoordinatorView: View {
    var initialType: KanaType = .hiragana
    var onDismiss: () -> Void
    
    @State private var flowState: KanaExerciseFlowState = .config
    @State private var config = KanaQuizConfig.load()
    @State private var currentQuestions: [KanaQuizQuestion] = []
    @State private var sessionSummary: KanaSessionSummary? = nil
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            switch flowState {
            case .config:
                KanaExerciseConfigView(
                    config: $config,
                    onStartQuiz: { selectedConfig in
                        self.config = selectedConfig
                        selectedConfig.save()
                        let questions = KanaDataService.shared.generateQuiz(config: selectedConfig)
                        guard !questions.isEmpty else { return }
                        self.currentQuestions = questions
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.flowState = .quiz
                        }
                    },
                    onDismiss: onDismiss
                )
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                
            case .quiz:
                KanaSpeedQuizView(
                    questions: currentQuestions,
                    config: config,
                    onFinish: { summary in
                        self.sessionSummary = summary
                        ActivityService.shared.recordKanaSession(summary)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.flowState = .result
                        }
                    },
                    onQuit: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.flowState = .config
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .result:
                if let summary = sessionSummary {
                    KanaExerciseResultView(
                        summary: summary,
                        onRetrySameQuestions: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.flowState = .quiz
                            }
                        },
                        onChangeConfig: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.flowState = .config
                            }
                        },
                        onFinish: onDismiss
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
            }
        }
        .onAppear {
            config.kanaType = initialType
        }
    }
}
