import SwiftUI

enum ExerciseFlowState {
    case config
    case quiz
    case result
}

struct ExerciseCoordinatorView: View {
    var initialConfig: QuizConfig? = nil
    var customQuestions: [QuizQuestion]? = nil
    var startImmediately: Bool = false
    var onDismiss: () -> Void
    
    @State private var flowState: ExerciseFlowState
    @State private var config: QuizConfig
    @State private var currentQuestions: [QuizQuestion] = []
    @State private var sessionResult: QuizSessionResult? = nil
    
    init(
        initialConfig: QuizConfig? = nil,
        customQuestions: [QuizQuestion]? = nil,
        startImmediately: Bool = false,
        onDismiss: @escaping () -> Void
    ) {
        self.initialConfig = initialConfig
        self.customQuestions = customQuestions
        self.startImmediately = startImmediately
        self.onDismiss = onDismiss
        
        let loadedConfig = initialConfig ?? QuizConfig.load()
        self._config = State(initialValue: loadedConfig)
        
        if startImmediately {
            self._flowState = State(initialValue: .quiz)
            let questions = customQuestions ?? ExerciseService.shared.generateQuiz(config: loadedConfig)
            self._currentQuestions = State(initialValue: questions)
        } else {
            self._flowState = State(initialValue: .config)
        }
    }
    
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
                        ActivityService.shared.recordWordSession(result)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.flowState = .result
                        }
                    },
                    onQuit: {
                        if startImmediately {
                            onDismiss()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.flowState = .config
                            }
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .result:
                if let result = sessionResult {
                    ExerciseResultView(
                        summary: result,
                        onRetrySameQuestions: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.flowState = .quiz
                            }
                        },
                        onChangeConfig: {
                            if startImmediately {
                                onDismiss()
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    self.flowState = .config
                                }
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
