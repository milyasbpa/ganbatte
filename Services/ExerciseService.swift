import Foundation

final class ExerciseService {
    static let shared = ExerciseService()
    
    private init() {}
    
    func generateQuiz(config: QuizConfig) -> [QuizQuestion] {
        // 1. Fetch matching words pool in natural order
        var candidateWords = DatabaseService.shared.fetchWords(
            level: config.level,
            type: config.type,
            searchQuery: "",
            limit: 2000,
            offset: 0
        )
        
        // Fallback to broader pool if filtered pool is too small
        if candidateWords.count < 4 {
            candidateWords = DatabaseService.shared.fetchWords(
                level: .all,
                type: .all,
                searchQuery: "",
                limit: 2000,
                offset: 0
            )
        }
        
        guard !candidateWords.isEmpty else { return [] }
        
        // 2. Select target words within user range (startWord ... endWord, 1-indexed)
        let totalCount = candidateWords.count
        let clampedStart = max(1, min(config.startWord, totalCount))
        let clampedEnd = max(clampedStart, min(config.endWord, totalCount))
        
        let startIdx = clampedStart - 1
        let endIdx = clampedEnd - 1
        
        let sliceWords = Array(candidateWords[startIdx...endIdx])
        
        // Target words within range shuffled for quiz variety
        let targetWords = sliceWords.shuffled()
        
        // 3. For each target word, create 4 options (1 correct + 3 distractors)
        var questions: [QuizQuestion] = []
        
        for (index, target) in targetWords.enumerated() {
            // Pick 3 distractors matching same type or pool
            var otherWords = candidateWords.filter { $0.id != target.id }
            otherWords.shuffle()
            let distractors = Array(otherWords.prefix(3))
            
            var options = [target] + distractors
            options.shuffle()
            
            let correctIndex = options.firstIndex(where: { $0.id == target.id }) ?? 0
            
            let question = QuizQuestion(
                questionNumber: index + 1,
                targetWord: target,
                options: options,
                correctIndex: correctIndex,
                questionType: config.questionType
            )
            questions.append(question)
        }
        
        return questions
    }
    
    // MARK: - Generate Focused Mistake Quiz
    func generateMistakeQuiz(wordIds: [Int], questionType: QuestionType) -> [QuizQuestion] {
        guard !wordIds.isEmpty else { return [] }
        
        let targetWords = DatabaseService.shared.fetchWords(by: wordIds).shuffled()
        guard !targetWords.isEmpty else { return [] }
        
        // Distractor pool
        var candidateWords = DatabaseService.shared.fetchWords(
            level: .all,
            type: .all,
            searchQuery: "",
            limit: 1000,
            offset: 0
        )
        if candidateWords.count < 4 {
            candidateWords = targetWords
        }
        
        var questions: [QuizQuestion] = []
        for (index, target) in targetWords.enumerated() {
            var otherWords = candidateWords.filter { $0.id != target.id }
            otherWords.shuffle()
            let distractors = Array(otherWords.prefix(3))
            
            var options = [target] + distractors
            options.shuffle()
            
            let correctIndex = options.firstIndex(where: { $0.id == target.id }) ?? 0
            
            let question = QuizQuestion(
                questionNumber: index + 1,
                targetWord: target,
                options: options,
                correctIndex: correctIndex,
                questionType: questionType
            )
            questions.append(question)
        }
        return questions
    }
}
