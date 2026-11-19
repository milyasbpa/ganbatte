import SwiftUI

enum KanaExerciseFlowState {
    case config
    case quiz
    case result
}

struct KanaExerciseCoordinatorView: View {
    var initialConfig: KanaQuizConfig? = nil
    var initialType: KanaType = .hiragana
    var startImmediately: Bool = false
    var onDismiss: () -> Void
    
    @State private var flowState: KanaExerciseFlowState
    @State private var config: KanaQuizConfig
    @State private var currentQuestions: [KanaQuizQuestion] = []
    @State private var sessionSummary: KanaSessionSummary? = nil
    
    init(
        initialConfig: KanaQuizConfig? = nil,
        initialType: KanaType = .hiragana,
        startImmediately: Bool = false,
        onDismiss: @escaping () -> Void
    ) {
        self.initialConfig = initialConfig
        self.initialType = initialType
        self.startImmediately = startImmediately
        self.onDismiss = onDismiss
        
        var loadedConfig = initialConfig ?? KanaQuizConfig.load()
        if initialConfig == nil {
            loadedConfig.kanaType = initialType
        }
        self._config = State(initialValue: loadedConfig)
        
        if startImmediately {
            self._flowState = State(initialValue: .quiz)
            let questions = KanaDataService.shared.generateQuiz(config: loadedConfig)
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
                if let summary = sessionSummary {
                    KanaExerciseResultView(
                        summary: summary,
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
