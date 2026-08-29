import Foundation
import CoreGraphics
import UIKit

enum AnswerChoice: String, Codable, CaseIterable, Identifiable, Hashable {
    case A, B, C, D, E
    var id: String { rawValue }
}

enum ResponseStatus: String, Codable, CaseIterable, Hashable {
    case selected, empty, multiple, weak, uncertain, invalidRegion
    var needsReview: Bool { self == .multiple || self == .weak || self == .uncertain || self == .invalidRegion }
    var arabicTitle: String {
        switch self {
        case .selected: return "محدد"
        case .empty: return "فارغ"
        case .multiple: return "متعدد"
        case .weak: return "ضعيف"
        case .uncertain: return "غير مؤكد"
        case .invalidRegion: return "منطقة غير صالحة"
        }
    }
}

struct NormalizedPoint: Codable, Hashable { var x: Double; var y: Double }
struct NormalizedRect: Codable, Hashable { var x: Double; var y: Double; var width: Double; var height: Double }

struct TemplateQuestionDefinition: Codable, Hashable, Identifiable {
    var id: Int { questionNumber }
    var questionNumber: Int
    var choices: [AnswerChoice]
    var bubbleCoordinates: [AnswerChoice: NormalizedPoint]
    var bubbleRadius: Double
    var column: Int?
}

struct StudentIDDefinition: Codable, Hashable {
    var columns: Int
    var rows: Int
    var gridRect: NormalizedRect
    var prefix: String?
    var bubbleRadius: Double
}

struct MarkerDefinition: Codable, Hashable {
    var topLeft: NormalizedPoint
    var topRight: NormalizedPoint
    var bottomLeft: NormalizedPoint
    var bottomRight: NormalizedPoint
    var markerSize: Double
}

struct CalibrationProfile: Codable, Hashable {
    var darknessThreshold: Double
    var fillRatioThreshold: Double
    var weakMarkThreshold: Double
    var uncertainMargin: Double
}

struct TemplateDefinition: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var revision: Int
    var pageAspectRatio: Double
    var questionsCount: Int
    var choicesPerQuestion: [AnswerChoice]
    var questions: [TemplateQuestionDefinition]
    var studentID: StudentIDDefinition
    var markers: MarkerDefinition
    var ignoredAreas: [NormalizedRect]?
    var calibration: CalibrationProfile
}

struct BubbleMeasurement: Codable, Hashable {
    var darkness: Double
    var fillRatio: Double
    var contrast: Double
    var isFilled: Bool
    var confidence: Double
}

struct OMRQuestionResult: Codable, Hashable, Identifiable {
    var id: Int { questionNumber }
    var questionNumber: Int
    var selectedChoices: [AnswerChoice]
    var status: ResponseStatus
    var confidence: Double
    var measurements: [AnswerChoice: BubbleMeasurement]
    var primaryChoice: AnswerChoice?
}

enum ScannerPipelineStage: String, Codable, CaseIterable {
    case idle, detectingPaper, checkingQuality, aligning, readingStudentID, readingAnswers, calculating, complete, error
    var arabicMessage: String {
        switch self {
        case .idle: return "جاهز للمسح"
        case .detectingPaper: return "جارٍ اكتشاف ورقة الإجابة وتحديد الأطراف..."
        case .checkingQuality: return "جارٍ فحص حدة الصورة والإضاءة والتباين..."
        case .aligning: return "جارٍ محاذاة علامات الزوايا وتصحيح المنظور..."
        case .readingStudentID: return "جارٍ قراءة شبكة رقم الطالب..."
        case .readingAnswers: return "جارٍ فحص إجابات الأسئلة..."
        case .calculating: return "جارٍ حساب الدرجات والتحقق من الموثوقية..."
        case .complete: return "تم مسح ورقة الإجابة بنجاح"
        case .error: return "حدث خطأ أثناء المعالجة"
        }
    }
}

struct OMRProcessingResult: Codable, Hashable {
    var studentID: String
    var studentIDConfidence: Double
    var questions: [OMRQuestionResult]
    var needsReview: Bool
    var qualityScore: Double
    var processingTimeMs: Double
    var correctedImageJPEGData: Data?
    var pipelineStage: ScannerPipelineStage
    var errorMessage: String?
}

struct Student: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var studentID: String
    var classroomId: String
    var createdAt: Date
    var notes: String?
}

struct Classroom: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var grade: String?
    var createdAt: Date
    var description: String?
}

struct Question: Codable, Hashable, Identifiable {
    var id: String
    var number: Int
    var correctChoice: AnswerChoice
    var weight: Double
}

struct AnswerKey: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var entries: [Int: AnswerChoice]
}

struct ExamTemplate: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var definition: TemplateDefinition
}

struct StudentResponse: Codable, Hashable, Identifiable {
    var id: String
    var questionNumber: Int
    var selectedChoices: [AnswerChoice]
    var correctChoice: AnswerChoice
    var status: ResponseStatus
    var confidence: Double
    var manuallyEdited: Bool
    var isCorrect: Bool?
}

struct ExamResult: Codable, Hashable, Identifiable {
    var id: String
    var examId: String
    var studentId: String?
    var studentID: String
    var studentName: String?
    var classroomName: String?
    var scannedAt: Date
    var score: Double
    var maximumScore: Double
    var percentage: Double
    var correctCount: Int
    var wrongCount: Int
    var emptyCount: Int
    var multipleCount: Int
    var needsReview: Bool
    var correctedImageJPEGData: Data?
    var responses: [StudentResponse]
}

struct Exam: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var subject: String
    var date: Date
    var questions: [Question]
    var answerKey: AnswerKey
    var templateId: String
    var maximumScore: Double
    var createdAt: Date
}

extension Date {
    var smartDate: String { formatted(date: .abbreviated, time: .omitted) }
    var smartDateTime: String { formatted(date: .abbreviated, time: .shortened) }
}

