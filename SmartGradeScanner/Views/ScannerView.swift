import SwiftUI
import PhotosUI

struct ScannerView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @StateObject private var processor = OMRProcessor()
    var selectedExamId: String?
    @State private var activeExamId = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var processing = false
    @State private var review: OMRProcessingResult?

    var activeExam: Exam? { store.exams.first { $0.id == (activeExamId.isEmpty ? (selectedExamId ?? "") : activeExamId) } ?? store.exams.first }
    var activeTemplate: TemplateDefinition? { guard let exam = activeExam else { return nil }; return store.templates.first { $0.id == exam.templateId }?.definition ?? store.templates.first?.definition }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                GlassCard { VStack(alignment: .leading, spacing: 10) {
                    HStack { Label(store.isArabic ? "ماسح ورقة الإجابة الذكي" : "Smart OMR Scanner", systemImage: "camera.viewfinder").font(.title3.bold()); Spacer() }
                    Text(store.isArabic ? "ارفع صورة ورقة الإجابة. سيقرأ التطبيق رقم الطالب، يصنف الفقاعات، ثم يفتح شاشة مراجعة قبل حفظ النتيجة." : "Upload an answer sheet image, decode student ID and bubbles, then review before saving.").font(.subheadline).foregroundStyle(.secondary)
                    Picker(store.isArabic ? "الامتحان النشط" : "Active Exam", selection: $activeExamId) { ForEach(store.exams) { Text("\($0.name) (\($0.questions.count)Q)").tag($0.id) } }.pickerStyle(.menu)
                }}
                cameraStage
                if processing { pipelineView }
                HStack { MetricTile(title: "Templates", value: "\(store.templates.count)", icon: "square.grid.3x3.fill"); MetricTile(title: "Results", value: "\(store.results.count)", icon: "checklist.checked", tint: Palette.emerald) }
            }.padding()
        }
        .onAppear { activeExamId = selectedExamId ?? store.exams.first?.id ?? "" }
        .onChange(of: selectedPhoto) { _, newItem in Task { await loadPhoto(newItem) } }
        .sheet(item: Binding(get: { review.map { ReviewBox(result: $0) } }, set: { if $0 == nil { review = nil } })) { box in
            if let exam = activeExam { ScanReviewView(omr: box.result, exam: exam) { result in store.saveResult(result); review = nil } onDiscard: { review = nil } }
        }
    }

    var cameraStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32).fill(LinearGradient(colors: [Palette.slate900, .black], startPoint: .top, endPoint: .bottom))
            if let selectedImage { Image(uiImage: selectedImage).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 26)).padding(10) }
            VStack { HStack { corner; Spacer(); corner.rotationEffect(.degrees(90)) }; Spacer(); HStack { corner.rotationEffect(.degrees(-90)); Spacer(); corner.rotationEffect(.degrees(180)) } }.padding(34)
            VStack(spacing: 14) {
                if selectedImage == nil { Image(systemName: "doc.viewfinder").font(.system(size: 54)).foregroundStyle(.white.opacity(0.8)); Text(store.isArabic ? "ضع الورقة داخل الإطار أو اختر صورة" : "Place sheet in frame or choose image").foregroundStyle(.white.opacity(0.85)).font(.headline) }
                Spacer()
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(store.isArabic ? "رفع صورة" : "Upload", systemImage: "photo.on.rectangle").padding().frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 18)) }
                    Button { Task { await processCurrent() } } label: { Label(store.isArabic ? "مسح الآن" : "Scan", systemImage: "sparkles").padding().frame(maxWidth: .infinity).foregroundStyle(.white).background(Palette.indigo, in: RoundedRectangle(cornerRadius: 18)) }.disabled(selectedImage == nil || processing)
                }.font(.headline).padding()
            }.padding(.top, 70)
        }.frame(minHeight: 480)
    }

    var corner: some View { Rectangle().trim(from: 0, to: 0.5).stroke(Palette.indigo, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)).frame(width: 54, height: 54) }
    var pipelineView: some View { GlassCard { VStack(alignment: .leading, spacing: 10) { Text(processor.stage.arabicMessage).font(.headline); ProgressView(value: processor.progress).tint(Palette.indigo); Text("\(Int(processor.progress * 100))%").font(.caption).foregroundStyle(.secondary) } } }

    func loadPhoto(_ item: PhotosPickerItem?) async { guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }; selectedImage = image }
    func processCurrent() async { guard let image = selectedImage, let template = activeTemplate else { return }; processing = true; let result = await processor.process(image: image, template: template); processing = false; review = result }
}

struct ReviewBox: Identifiable, Equatable { let id = UUID(); let result: OMRProcessingResult }

