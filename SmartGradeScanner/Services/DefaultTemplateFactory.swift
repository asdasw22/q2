import Foundation

struct DefaultTemplateFactory {
    static let choices: [AnswerChoice] = [.A, .B, .C, .D, .E]

    static func make20QuestionTemplate() -> TemplateDefinition {
        var questions: [TemplateQuestionDefinition] = []
        let col1StartX = 0.12, col2StartX = 0.56, choiceSpacingX = 0.062
        let startY = 0.54, rowSpacingY = 0.038, bubbleRadius = 0.016
        for q in 1...20 {
            let isCol1 = q <= 10
            let rowIndex = isCol1 ? q - 1 : q - 11
            let startX = isCol1 ? col1StartX : col2StartX
            let y = startY + Double(rowIndex) * rowSpacingY
            var coords: [AnswerChoice: NormalizedPoint] = [:]
            for (idx, choice) in choices.enumerated() {
                coords[choice] = NormalizedPoint(x: startX + Double(idx) * choiceSpacingX, y: y)
            }
            questions.append(.init(questionNumber: q, choices: choices, bubbleCoordinates: coords, bubbleRadius: bubbleRadius, column: isCol1 ? 1 : 2))
        }
        return baseTemplate(id: "default-20q-template", name: "SmartGrade 20-Question Standard Template", count: 20, questions: questions, studentRect: .init(x: 0.18, y: 0.20, width: 0.64, height: 0.25), idRadius: 0.014)
    }

    static func make50QuestionTemplate() -> TemplateDefinition {
        var questions: [TemplateQuestionDefinition] = []
        let col1StartX = 0.10, col2StartX = 0.55, choiceSpacingX = 0.065
        let startY = 0.44, rowSpacingY = 0.021, bubbleRadius = 0.012
        for q in 1...50 {
            let isCol1 = q <= 25
            let rowIndex = isCol1 ? q - 1 : q - 26
            let startX = isCol1 ? col1StartX : col2StartX
            let y = startY + Double(rowIndex) * rowSpacingY
            var coords: [AnswerChoice: NormalizedPoint] = [:]
            for (idx, choice) in choices.enumerated() {
                coords[choice] = NormalizedPoint(x: startX + Double(idx) * choiceSpacingX, y: y)
            }
            questions.append(.init(questionNumber: q, choices: choices, bubbleCoordinates: coords, bubbleRadius: bubbleRadius, column: isCol1 ? 1 : 2))
        }
        return baseTemplate(id: "default-50q-template", name: "SmartGrade 50-Question Standard Template", count: 50, questions: questions, studentRect: .init(x: 0.20, y: 0.14, width: 0.60, height: 0.24), idRadius: 0.012)
    }

    private static func baseTemplate(id: String, name: String, count: Int, questions: [TemplateQuestionDefinition], studentRect: NormalizedRect, idRadius: Double) -> TemplateDefinition {
        TemplateDefinition(
            id: id,
            name: name,
            revision: 1,
            pageAspectRatio: 0.707,
            questionsCount: count,
            choicesPerQuestion: choices,
            questions: questions,
            studentID: .init(columns: 9, rows: 10, gridRect: studentRect, prefix: "320", bubbleRadius: idRadius),
            markers: .init(topLeft: .init(x: 0.05, y: 0.04), topRight: .init(x: 0.95, y: 0.04), bottomLeft: .init(x: 0.05, y: 0.96), bottomRight: .init(x: 0.95, y: 0.96), markerSize: 0.035),
            ignoredAreas: nil,
            calibration: .init(darknessThreshold: 140, fillRatioThreshold: 0.38, weakMarkThreshold: 0.22, uncertainMargin: 0.15)
        )
    }
}

