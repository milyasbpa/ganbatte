import Foundation

final class ExerciseService {
    static let shared = ExerciseService()
    
    private init() {}
    
    func generateQuiz(config: QuizConfig) -> [QuizQuestion] {
        // 1. Fetch matching words pool
        var candidateWords = DatabaseService.shared.fetchWords(
            level: config.level,
            type: config.type,
            searchQuery: "",
            limit: 500,
            offset: 0
        )
        
        // Fallback to broader pool if filtered pool is too small
        if candidateWords.count < 4 {
            candidateWords = DatabaseService.shared.fetchWords(
                level: .all,
                type: .all,
                searchQuery: "",
                limit: 500,
                offset: 0
            )
        }
        
        guard !candidateWords.isEmpty else { return [] }
        
        // 2. Select target words
        var shuffledCandidates = candidateWords.shuffled()
        let count = min(config.questionCount, shuffledCandidates.count)
        let targetWords = Array(shuffledCandidates.prefix(count))
        
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
}
