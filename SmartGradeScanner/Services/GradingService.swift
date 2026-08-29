import Foundation

struct GradingService {
    static func grade(_ omr: OMRProcessingResult, exam: Exam, matchedStudent: Student?, classroomName: String?) -> ExamResult {
        var responses: [StudentResponse] = []
        var correct = 0, wrong = 0, empty = 0, multiple = 0
        var earned = 0.0, maxScore = 0.0
        for q in exam.questions {
            let correctChoice = exam.answerKey.entries[q.number] ?? q.correctChoice
            maxScore += q.weight
            let omrQ = omr.questions.first { $0.questionNumber == q.number }
            let selected = omrQ?.selectedChoices ?? []
            let status = omrQ?.status ?? .empty
            var isCorrect = false
            if status == .empty || selected.isEmpty { empty += 1 }
            else if status == .multiple || selected.count > 1 { multiple += 1; wrong += 1 }
            else if selected.first == correctChoice { correct += 1; earned += q.weight; isCorrect = true }
            else { wrong += 1 }
            responses.append(StudentResponse(id: "resp_\(exam.id)_\(q.number)_\(UUID().uuidString)", questionNumber: q.number, selectedChoices: selected, correctChoice: correctChoice, status: status, confidence: omrQ?.confidence ?? 0, manuallyEdited: false, isCorrect: isCorrect))
        }
        return ExamResult(id: "result_\(UUID().uuidString)", examId: exam.id, studentId: matchedStudent?.id, studentID: omr.studentID, studentName: matchedStudent?.name, classroomName: classroomName, scannedAt: Date(), score: round(earned * 10) / 10, maximumScore: round(maxScore * 10) / 10, percentage: maxScore > 0 ? round((earned / maxScore) * 1000) / 10 : 0, correctCount: correct, wrongCount: wrong, emptyCount: empty, multipleCount: multiple, needsReview: omr.needsReview, correctedImageJPEGData: omr.correctedImageJPEGData, responses: responses)
    }

    static func recalculate(_ existing: ExamResult, exam: Exam, updatedResponses: [StudentResponse]) -> ExamResult {
        var correct = 0, wrong = 0, empty = 0, multiple = 0
        var earned = 0.0, maxScore = 0.0
        let recalculated = updatedResponses.map { r -> StudentResponse in
            var item = r
            let q = exam.questions.first { $0.number == r.questionNumber }
            let weight = q?.weight ?? 1
            maxScore += weight
            let key = exam.answerKey.entries[r.questionNumber] ?? r.correctChoice
            item.correctChoice = key
            if r.selectedChoices.isEmpty || r.status == .empty { empty += 1; item.isCorrect = false }
            else if r.selectedChoices.count > 1 || r.status == .multiple { multiple += 1; wrong += 1; item.isCorrect = false }
            else if r.selectedChoices.first == key { correct += 1; earned += weight; item.isCorrect = true }
            else { wrong += 1; item.isCorrect = false }
            return item
        }
        var out = existing
        out.score = round(earned * 10) / 10; out.maximumScore = round(maxScore * 10) / 10
        out.percentage = maxScore > 0 ? round((earned / maxScore) * 1000) / 10 : 0
        out.correctCount = correct; out.wrongCount = wrong; out.emptyCount = empty; out.multipleCount = multiple
        out.needsReview = recalculated.contains { $0.status.needsReview && !$0.manuallyEdited }
        out.responses = recalculated
        return out
    }
}

