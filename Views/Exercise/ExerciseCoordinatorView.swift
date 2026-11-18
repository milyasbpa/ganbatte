import SwiftUI

enum ExerciseFlowState {
    case config
    case quiz
    case result
}

struct ExerciseCoordinatorView: View {
    var onDismiss: () -> Void
    
    @State private var flowState: ExerciseFlowState = .config
    @State private var config = QuizConfig.load()
    @State private var currentQuestions: [QuizQuestion] = []
    @State private var sessionResult: QuizSessionResult? = nil
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            switch flowState {
            case .config:
                ExerciseConfigView(
                    config: $config,
                    onStartQuiz: { selectedConfig in
                        self.config = selectedConfig
                        selectedConfig.save() // Persist configuration
                        let questions = ExerciseService.shared.generateQuiz(config: selectedConfig)
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
                ExerciseQuizView(
                    questions: currentQuestions,
                    config: config,
                    onFinish: { result in
                        self.sessionResult = result
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
                if let result = sessionResult {
                    ExerciseResultView(
                        summary: result,
                        onRetrySameQuestions: {
                            // Restart quiz with the exact same questions
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
    }
}
