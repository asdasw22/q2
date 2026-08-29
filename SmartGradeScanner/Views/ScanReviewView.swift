import SwiftUI

struct ScanReviewView: View {
    @EnvironmentObject private var store: SmartGradeStore
    
    let omr: OMRProcessingResult
    let exam: Exam
    let onSave: (ExamResult) -> Void
    let onDiscard: () -> Void
    
    @State private var studentID: String = ""
    @State private var responses: [StudentResponse] = []
    @State private var current: ExamResult?

    var body: some View {
        NavigationStack {
            List {
                if let result = current {
                    
                    Section {
                        LabeledContent("Student") {
                            Text(studentID.isEmpty ? "Needs review" : studentID)
                        }
                        
                        LabeledContent("Score") {
                            Text(
                                "\(result.score, specifier: "%.1f") / \(result.maximumScore, specifier: "%.1f")"
                            )
                        }
                        
                        LabeledContent("Percentage") {
                            Text(
                                "\(result.percentage, specifier: "%.1f")%"
                            )
                        }
                        
                        if result.needsReview {
                            Label(
                                "Some answers need manual review",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(Color.orange)
                        }
                    }

                    Section("Student") {
                        TextField("Student ID", text: $studentID)
                            .keyboardType(.numberPad)
                        
                        if let student = store.findStudent(studentID: studentID) {
                            Label(
                                student.name,
                                systemImage: "checkmark.circle.fill"
                            )
                            .foregroundStyle(Color.green)
                        } else {
                            Label(
                                "Unregistered student ID",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(Color.orange)
                        }
                    }

                    Section("Questions") {
                        ForEach(responses) { response in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Q\(response.questionNumber)")
                                        .frame(
                                            width: 42,
                                            alignment: .leading
                                        )
                                    
                                    Text(
                                        response.selectedChoices
                                            .map { $0.rawValue }
                                            .joined(separator: " + ")
                                            .ifEmpty("Empty")
                                    )
                                    
                                    Spacer()
                                    
                                    StatusPill(status: response.status)
                                    
                                    Text(
                                        "\(response.confidence, specifier: "%.0f")%"
                                    )
                                    .font(.caption.monospacedDigit())
                                }
                                
                                HStack {
                                    ForEach(AnswerChoice.allCases) { choice in
                                        Button(choice.rawValue) {
                                            toggle(
                                                response.questionNumber,
                                                choice
                                            )
                                        }
                                        .font(.caption.bold())
                                        .frame(
                                            width: 32,
                                            height: 32
                                        )
                                        .background(
                                            response.selectedChoices.contains(choice)
                                                ? Color.accentColor
                                                : Color.gray.opacity(0.12),
                                            in: Circle()
                                        )
                                        .foregroundStyle(
                                            response.selectedChoices.contains(choice)
                                                ? Color.white
                                                : Color.primary
                                        )
                                    }
                                }
                                
                                Text(
                                    "Correct: \(response.correctChoice.rawValue)"
                                )
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(
                store.isArabic
                    ? "مراجعة المسح"
                    : "Review Scan"
            )
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Discard") {
                        onDiscard()
                    }
                }
                
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save Result") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                buildInitial()
            }
        }
    }

    private func buildInitial() {
        let student = store.findStudent(
            studentID: omr.studentID
        )
        
        studentID = omr.studentID
        
        let result = GradingService.grade(
            omr,
            exam: exam,
            matchedStudent: student,
            classroomName: student.flatMap {
                store.classroomName(
                    for: $0.classroomId
                )
            }
        )
        
        current = result
        responses = result.responses
    }

    private func toggle(
        _ questionNumber: Int,
        _ choice: AnswerChoice
    ) {
        responses = responses.map { response in
            var updatedResponse = response
            
            if updatedResponse.questionNumber == questionNumber {
                
                if updatedResponse.selectedChoices.contains(choice) {
                    updatedResponse.selectedChoices = []
                } else {
                    updatedResponse.selectedChoices = [choice]
                }
                
                updatedResponse.status =
                    updatedResponse.selectedChoices.isEmpty
                    ? .empty
                    : .selected
                
                updatedResponse.confidence = 100
                updatedResponse.manuallyEdited = true
            }
            
            return updatedResponse
        }
        
        if let result = current {
            current = GradingService.recalculate(
                result,
                exam: exam,
                updatedResponses: responses
            )
        }
    }

    private func save() {
        guard var result = current else {
            return
        }
        
        let student = store.findStudent(
            studentID: studentID
        )
        
        result.studentID = studentID
        result.studentId = student?.id
        result.studentName =
            student?.name ?? result.studentName
        
        result.classroomName = student.flatMap {
            store.classroomName(
                for: $0.classroomId
            )
        }
        
        onSave(result)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
