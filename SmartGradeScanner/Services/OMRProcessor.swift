import Foundation
import UIKit
import CoreGraphics
import Combine

struct GrayImage {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    func value(x: Int, y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < width, y < height else { return 255 }
        return pixels[y * width + x]
    }

    func sampleCircle(cx: Double, cy: Double, radius: Double, threshold: Double) -> (darkness: Double, fillRatio: Double, contrast: Double) {
        let minX = max(0, Int(cx - radius)), maxX = min(width - 1, Int(cx + radius))
        let minY = max(0, Int(cy - radius)), maxY = min(height - 1, Int(cy + radius))
        var total = 0, filled = 0, sum = 0
        let r2 = radius * radius
        for y in minY...maxY {
            for x in minX...maxX {
                let dx = Double(x) - cx, dy = Double(y) - cy
                guard dx * dx + dy * dy <= r2 else { continue }
                let v = Int(value(x: x, y: y)); total += 1; sum += v
                if Double(v) <= threshold { filled += 1 }
            }
        }
        guard total > 0 else { return (255, 0, 0) }
        let avg = Double(sum) / Double(total)
        return (avg, Double(filled) / Double(total), max(0, 255 - avg))
    }

    static func from(_ image: UIImage, maxDimension: CGFloat = 1200) -> GrayImage? {
        guard let cg = image.normalized().cgImage else { return nil }
        let scale = min(1, maxDimension / CGFloat(max(cg.width, cg.height)))
        let w = max(1, Int(CGFloat(cg.width) * scale)), h = max(1, Int(CGFloat(cg.height) * scale))
        var buffer = [UInt8](repeating: 255, count: w * h)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(data: &buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return GrayImage(width: w, height: h, pixels: buffer)
    }
}

extension UIImage {
    func normalized() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return img
    }
}

struct CalibratedThresholds {
    var markDarknessThreshold: Double
    var fillRatioThreshold: Double
    var weakMarkThreshold: Double
    var uncertainMargin: Double
}

struct ThresholdCalibrator {
    static func calibrate(_ gray: GrayImage, profile: CalibrationProfile) -> CalibratedThresholds {
        let stepSize = max(1, gray.pixels.count / 5000)
        let sample = stride(from: 0, to: gray.pixels.count, by: stepSize).map { Double(gray.pixels[$0]) }.sorted()
        let median = sample.isEmpty ? 180 : sample[sample.count / 2]
        let adjusted = min(170, max(105, median * 0.72))
        return CalibratedThresholds(markDarknessThreshold: min(profile.darknessThreshold, adjusted), fillRatioThreshold: profile.fillRatioThreshold, weakMarkThreshold: profile.weakMarkThreshold, uncertainMargin: profile.uncertainMargin)
    }
}

struct BubbleClassifier {
    static func classifyQuestion(gray: GrayImage, question: TemplateQuestionDefinition, thresholds: CalibratedThresholds) -> OMRQuestionResult {
        var measurements: [AnswerChoice: BubbleMeasurement] = [:]
        var scored: [(AnswerChoice, Double, Double, Double)] = []
        for choice in question.choices {
            guard let c = question.bubbleCoordinates[choice] else { continue }
            let sample = gray.sampleCircle(cx: c.x * Double(gray.width), cy: c.y * Double(gray.height), radius: question.bubbleRadius * Double(gray.width), threshold: thresholds.markDarknessThreshold)
            let filled = sample.fillRatio >= thresholds.fillRatioThreshold
            let confidence = filled ? min(100, 50 + sample.fillRatio * 50) : (sample.fillRatio <= thresholds.weakMarkThreshold * 0.4 ? min(100, 80 + (1 - sample.fillRatio) * 20) : 40)
            measurements[choice] = BubbleMeasurement(darkness: sample.darkness, fillRatio: sample.fillRatio, contrast: sample.contrast, isFilled: filled, confidence: confidence)
            scored.append((choice, sample.fillRatio, sample.darkness, sample.contrast))
        }
        scored.sort { $0.1 > $1.1 }
        let top1 = scored.first
        let top2 = scored.dropFirst().first
        var status: ResponseStatus = .empty
        var selected: [AnswerChoice] = []
        var confidence = 95.0
        var primary: AnswerChoice?
        if top1 == nil || top1!.1 < thresholds.weakMarkThreshold {
            status = .empty; confidence = min(99, 90 + (1 - (top1?.1 ?? 0)) * 10)
        } else if top1!.1 >= thresholds.fillRatioThreshold {
            if let t2 = top2, t2.1 >= thresholds.fillRatioThreshold {
                status = .multiple; selected = scored.filter { $0.1 >= thresholds.fillRatioThreshold }.map { $0.0 }; confidence = 50
            } else if let t2 = top2, top1!.1 - t2.1 < thresholds.uncertainMargin {
                status = .uncertain; selected = [top1!.0]; primary = top1!.0; confidence = 60
            } else {
                status = .selected; selected = [top1!.0]; primary = top1!.0
                confidence = min(100, max(75, 75 + (top1!.1 - (top2?.1 ?? 0)) * 35))
            }
        } else {
            status = .weak; selected = [top1!.0]; primary = top1!.0; confidence = 55
        }
        return OMRQuestionResult(questionNumber: question.questionNumber, selectedChoices: selected, status: status, confidence: round(confidence), measurements: measurements, primaryChoice: primary)
    }
}

struct StudentIDDetector {
    static func detect(gray: GrayImage, definition: StudentIDDefinition, thresholds: CalibratedThresholds) -> (id: String, confidence: Double, hasErrors: Bool) {
        let rect = definition.gridRect
        let gx = rect.x * Double(gray.width), gy = rect.y * Double(gray.height)
        let gw = rect.width * Double(gray.width), gh = rect.height * Double(gray.height)
        let colW = gw / Double(definition.columns), rowH = gh / Double(definition.rows)
        var digits = ""
        var confidences: [Double] = []
        var errors = false
        for c in 0..<definition.columns {
            var scores: [(Int, Double)] = []
            for r in 0..<definition.rows {
                let sample = gray.sampleCircle(cx: gx + (Double(c) + 0.5) * colW, cy: gy + (Double(r) + 0.5) * rowH, radius: definition.bubbleRadius * Double(gray.width), threshold: thresholds.markDarknessThreshold)
                scores.append((r, sample.fillRatio))
            }
            scores.sort { $0.1 > $1.1 }
            let best = scores.first ?? (0,0), second = scores.dropFirst().first ?? (0,0)
            if best.1 < thresholds.weakMarkThreshold { errors = true; digits += "?"; confidences.append(25) }
            else { digits += "\(best.0)"; let margin = best.1 - second.1; confidences.append(min(100, max(45, 55 + margin * 100))) }
        }
        let avg = confidences.isEmpty ? 0 : confidences.reduce(0,+) / Double(confidences.count)
        return (digits, round(avg), errors)
    }
}

struct ImageQualityAnalyzer {
    static func analyze(_ gray: GrayImage) -> (quality: Double, acceptable: Bool) {
        guard gray.pixels.count > 10 else { return (0, false) }
        let stepSize = max(1, gray.pixels.count / 8000)
        var minV = 255, maxV = 0, sum = 0, n = 0
        for i in stride(from: 0, to: gray.pixels.count, by: stepSize) { let v = Int(gray.pixels[i]); minV = min(minV, v); maxV = max(maxV, v); sum += v; n += 1 }
        let contrast = Double(maxV - minV)
        let mean = Double(sum) / Double(max(1,n))
        let lightingPenalty = abs(mean - 205) * 0.25
        let score = max(0, min(100, contrast * 0.55 - lightingPenalty + 35))
        return (round(score), score > 25)
    }
}

@MainActor
final class OMRProcessor: ObservableObject {
    @Published var stage: ScannerPipelineStage = .idle
    @Published var progress: Double = 0

    func process(image: UIImage, template: TemplateDefinition) async -> OMRProcessingResult {
        let start = Date()
        func step(_ s: ScannerPipelineStage, _ p: Double) async { stage = s; progress = p; try? await Task.sleep(nanoseconds: 140_000_000) }
        await step(.detectingPaper, 0.15)
        guard let gray = GrayImage.from(image) else { return OMRProcessingResult(studentID: "?", studentIDConfidence: 0, questions: [], needsReview: true, qualityScore: 0, processingTimeMs: 0, correctedImageJPEGData: nil, pipelineStage: .error, errorMessage: "تعذر قراءة الصورة") }
        await step(.checkingQuality, 0.30)
        let quality = ImageQualityAnalyzer.analyze(gray)
        await step(.aligning, 0.45)
        let thresholds = ThresholdCalibrator.calibrate(gray, profile: template.calibration)
        await step(.readingStudentID, 0.60)
        let sid = StudentIDDetector.detect(gray: gray, definition: template.studentID, thresholds: thresholds)
        await step(.readingAnswers, 0.80)
        let questions = template.questions.map { BubbleClassifier.classifyQuestion(gray: gray, question: $0, thresholds: thresholds) }
        await step(.calculating, 0.95)
        let flagged = questions.contains { $0.status.needsReview }
        await step(.complete, 1.0)
        return OMRProcessingResult(studentID: sid.id, studentIDConfidence: sid.confidence, questions: questions, needsReview: sid.hasErrors || sid.confidence < 70 || flagged || !quality.acceptable, qualityScore: quality.quality, processingTimeMs: Date().timeIntervalSince(start) * 1000, correctedImageJPEGData: image.jpegData(compressionQuality: 0.82), pipelineStage: .complete, errorMessage: nil)
    }
}




