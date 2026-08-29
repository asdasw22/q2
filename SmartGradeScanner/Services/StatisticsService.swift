import Foundation

struct DistributionBucket: Identifiable, Hashable {
    var id: String { range }
    var range: String
    var count: Int
    var percentage: Double
}

struct QuestionAnalytics: Identifiable, Hashable {
    var id: Int { questionNumber }
    var questionNumber: Int
    var correctCount: Int
    var wrongCount: Int
    var emptyCount: Int
    var multipleCount: Int
    var totalAttempts: Int
    var correctPercentage: Double
    var choiceDistribution: [AnswerChoice: Int]
    var difficulty: String
}

struct ExamStatistics {
    var totalScanned: Int = 0
    var averageScore: Double = 0
    var averagePercentage: Double = 0
    var medianPercentage: Double = 0
    var highestScore: Double = 0
    var lowestScore: Double = 0
    var passCount: Int = 0
    var failCount: Int = 0
    var passRate: Double = 0
    var distribution: [DistributionBucket] = []
    var questionAnalytics: [QuestionAnalytics] = []
}

struct StatisticsService {
    static func compute(exam: Exam, results: [ExamResult], passingGrade: Double = 50) -> ExamStatistics {
        guard !results.isEmpty else { return ExamStatistics(distribution: emptyBuckets()) }
        let total = results.count
        let scores = results.map(\.score)
        let pcts = results.map(\.percentage).sorted()
        let median = total % 2 == 0 ? (pcts[total/2 - 1] + pcts[total/2]) / 2 : pcts[total/2]
        var buckets: [String: Int] = Dictionary(uniqueKeysWithValues: emptyBuckets().map { ($0.range, 0) })
        var qMap: [Int: (correct: Int, wrong: Int, empty: Int, multiple: Int, choices: [AnswerChoice: Int])] = [:]
        for q in exam.questions { qMap[q.number] = (0,0,0,0, Dictionary(uniqueKeysWithValues: AnswerChoice.allCases.map { ($0, 0) })) }
        var pass = 0
        for r in results {
            if r.percentage >= passingGrade { pass += 1 }
            if r.percentage >= 90 { buckets["90-100%", default: 0] += 1 }
            else if r.percentage >= 80 { buckets["80-89%", default: 0] += 1 }
            else if r.percentage >= 70 { buckets["70-79%", default: 0] += 1 }
            else if r.percentage >= 60 { buckets["60-69%", default: 0] += 1 }
            else if r.percentage >= 50 { buckets["50-59%", default: 0] += 1 }
            else { buckets["< 50%", default: 0] += 1 }
            for resp in r.responses {
                guard var stat = qMap[resp.questionNumber] else { continue }
                if resp.status == .empty { stat.empty += 1 }
                else if resp.status == .multiple { stat.multiple += 1 }
                else if resp.isCorrect == true { stat.correct += 1 }
                else { stat.wrong += 1 }
                for ch in resp.selectedChoices { stat.choices[ch, default: 0] += 1 }
                qMap[resp.questionNumber] = stat
            }
        }
        let order = ["90-100%","80-89%","70-79%","60-69%","50-59%","< 50%"]
        let dist = order.map { range in DistributionBucket(range: range, count: buckets[range, default: 0], percentage: round(Double(buckets[range, default: 0]) / Double(total) * 1000) / 10) }
        let itemStats = exam.questions.map { q -> QuestionAnalytics in
            let s = qMap[q.number] ?? (0,0,0,0,[:])
            let pct = round(Double(s.correct) / Double(total) * 1000) / 10
            let diff = pct >= 75 ? "سهل" : pct < 40 ? "صعب" : "متوسط"
            return QuestionAnalytics(questionNumber: q.number, correctCount: s.correct, wrongCount: s.wrong, emptyCount: s.empty, multipleCount: s.multiple, totalAttempts: total, correctPercentage: pct, choiceDistribution: s.choices, difficulty: diff)
        }
        return ExamStatistics(totalScanned: total, averageScore: round(scores.reduce(0,+)/Double(total)*10)/10, averagePercentage: round(results.map(\.percentage).reduce(0,+)/Double(total)*10)/10, medianPercentage: round(median*10)/10, highestScore: scores.max() ?? 0, lowestScore: scores.min() ?? 0, passCount: pass, failCount: total-pass, passRate: round(Double(pass)/Double(total)*1000)/10, distribution: dist, questionAnalytics: itemStats)
    }
    private static func emptyBuckets() -> [DistributionBucket] { [DistributionBucket(range:"90-100%",count:0,percentage:0),DistributionBucket(range:"80-89%",count:0,percentage:0),DistributionBucket(range:"70-79%",count:0,percentage:0),DistributionBucket(range:"60-69%",count:0,percentage:0),DistributionBucket(range:"50-59%",count:0,percentage:0),DistributionBucket(range:"< 50%",count:0,percentage:0)] }
}

