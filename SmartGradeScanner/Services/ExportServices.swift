import Foundation
import UIKit

struct CSVExportService {
    static func generateCSV(exam: Exam, results: [ExamResult]) -> String {
        let header = ["Student ID","Student Name","Classroom","Score","Maximum Score","Percentage (%)","Correct Answers","Wrong Answers","Empty Answers","Multiple Marks","Needs Review","Scanned At"].joined(separator: ",")
        let rows = results.map { r in
            [q(r.studentID), q(r.studentName ?? "Unknown"), q(r.classroomName ?? "-"), "\(r.score)", "\(r.maximumScore)", "\(r.percentage)%", "\(r.correctCount)", "\(r.wrongCount)", "\(r.emptyCount)", "\(r.multipleCount)", r.needsReview ? "Yes" : "No", q(r.scannedAt.smartDateTime)].joined(separator: ",")
        }
        return "\u{FEFF}# Exam: \(exam.name) | Subject: \(exam.subject) | Date: \(exam.date.smartDate)\r\n" + ([header] + rows).joined(separator: "\r\n")
    }
    private static func q(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
}

final class SharePresenter {
    static func share(text: String, filename: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? text.data(using: .utf8)?.write(to: url)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .present(vc, animated: true)
    }
}

