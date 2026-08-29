import SwiftUI
import PhotosUI
import VisionKit
import UIKit

struct ScannerView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @StateObject private var processor = OMRProcessor()
    var selectedExamId: String?

    @State private var activeExamId = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var processing = false
    @State private var review: OMRProcessingResult?
    @State private var showDocumentScanner = false
    @State private var showSystemCamera = false
    @State private var scannerMessage: String?

    var activeExam: Exam? { store.exams.first { $0.id == (activeExamId.isEmpty ? (selectedExamId ?? "") : activeExamId) } ?? store.exams.first }
    var activeTemplate: TemplateDefinition? { guard let exam = activeExam else { return nil }; return store.templates.first { $0.id == exam.templateId }?.definition ?? store.templates.first?.definition }
    var canUseDocumentScanner: Bool { VNDocumentCameraViewController.isSupported }
    var canUseSystemCamera: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                scannerPanel
                if processing { pipelineView }
                if let scannerMessage { messageCard(scannerMessage) }
                HStack {
                    MetricTile(title: store.isArabic ? "القوالب" : "Templates", value: "\(store.templates.count)", icon: "square.grid.3x3.fill", tint: Palette.gold)
                    MetricTile(title: store.isArabic ? "النتائج" : "Results", value: "\(store.results.count)", icon: "checklist.checked", tint: Palette.indigoLight)
                }
            }
            .padding()
        }
        .pageBackground()
        .onAppear { activeExamId = selectedExamId ?? store.exams.first?.id ?? "" }
        .onChange(of: selectedPhoto) { _, newItem in Task { await loadPhoto(newItem) } }
        .fullScreenCover(isPresented: $showDocumentScanner) {
            DocumentScannerView { images in
                showDocumentScanner = false
                guard let image = images.first else { scannerMessage = store.isArabic ? "لم يتم التقاط أي صفحة." : "No page captured."; return }
                selectedImage = image
                scannerMessage = store.isArabic ? "تم قص الورقة تلقائياً. جارٍ تحليلها..." : "Document auto-cropped. Processing..."
                Task { await processCurrent() }
            } onCancel: {
                showDocumentScanner = false
                scannerMessage = store.isArabic ? "تم إلغاء ماسح المستندات." : "Document scanner cancelled."
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showSystemCamera) {
            SystemCameraView { image in
                showSystemCamera = false
                selectedImage = image
                scannerMessage = store.isArabic ? "تم التقاط الصورة. جارٍ تحليلها..." : "Photo captured. Processing..."
                Task { await processCurrent() }
            } onCancel: {
                showSystemCamera = false
                scannerMessage = store.isArabic ? "تم إلغاء الكاميرا." : "Camera cancelled."
            }
            .ignoresSafeArea()
        }
        .sheet(item: Binding(get: { review.map { ReviewBox(result: $0) } }, set: { if $0 == nil { review = nil } })) { box in
            if let exam = activeExam { ScanReviewView(omr: box.result, exam: exam) { result in store.saveResult(result); review = nil } onDiscard: { review = nil } }
        }
    }

    var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(store.isArabic ? "ماسح الأوراق الكلاسيكي" : "Classic Sheet Scanner")
                            .font(.system(size: 25, weight: .black, design: .serif))
                            .foregroundStyle(LinearGradient(colors: [Palette.goldLight, Palette.gold], startPoint: .leading, endPoint: .trailing))
                        Text(store.isArabic ? "افتح ماسح iOS التلقائي بملء الشاشة لقص الورقة وتصحيح منظورها، ثم يتم التصحيح مباشرة." : "Open the full-screen iOS document scanner for automatic crop and perspective correction, then grade instantly.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.title.bold())
                        .foregroundStyle(Palette.gold)
                        .padding(13)
                        .background(Palette.indigo.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.gold.opacity(0.30), lineWidth: 1))
                }
                Picker(store.isArabic ? "الامتحان النشط" : "Active Exam", selection: $activeExamId) {
                    ForEach(store.exams) { Text("\($0.name) (\($0.questions.count)Q)").tag($0.id) }
                }
                .pickerStyle(.menu)
                .tint(Palette.gold)
            }
        }
    }

    var scannerPanel: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.black, Palette.obsidian, Palette.indigo.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    ornamentalFrame
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(28)
                    } else {
                        VStack(spacing: 18) {
                            Image(systemName: "doc.viewfinder.fill")
                                .font(.system(size: 72, weight: .light))
                                .foregroundStyle(LinearGradient(colors: [Palette.goldLight, Palette.gold, Palette.indigoLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Text(store.isArabic ? "أفضل جودة: استخدم ماسح المستندات التلقائي" : "Best quality: use automatic document scanner")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Palette.text)
                            Text(store.isArabic ? "يفتح كاميرا iOS كاملة، يكتشف الورقة، يقصها، ويعدل المنظور تلقائياً." : "It opens the full iOS camera, detects the sheet, crops and corrects perspective automatically.")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Palette.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 34)
                        }
                    }
                }
                .frame(minHeight: 460)
                .padding(14)

                controls
                    .padding([.horizontal, .bottom], 16)
            }
        }
    }

    var ornamentalFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(colors: [Palette.gold.opacity(0.55), Palette.indigoLight.opacity(0.36), Palette.goldDark.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
                .padding(18)
            VStack { HStack { corner; Spacer(); corner.rotationEffect(.degrees(90)) }; Spacer(); HStack { corner.rotationEffect(.degrees(-90)); Spacer(); corner.rotationEffect(.degrees(180)) } }
                .padding(34)
            VStack { Text("SMARTGRADE OMR").font(.caption.bold()).tracking(2).foregroundStyle(Palette.gold.opacity(0.90)).padding(.top, 30); Spacer() }
        }
        .allowsHitTesting(false)
    }

    var controls: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: store.isArabic ? "فتح ماسح المستندات التلقائي" : "Open Auto Document Scanner", icon: "doc.viewfinder") {
                if canUseDocumentScanner { showDocumentScanner = true } else { scannerMessage = store.isArabic ? "ماسح المستندات غير مدعوم على هذا الجهاز." : "Document scanner is not supported on this device." }
            }
            HStack(spacing: 12) {
                Button { if canUseSystemCamera { showSystemCamera = true } else { scannerMessage = store.isArabic ? "الكاميرا غير متاحة على هذا الجهاز." : "Camera is not available on this device." } } label: {
                    Label(store.isArabic ? "كاميرا النظام" : "System Camera", systemImage: "camera.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.indigo)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(store.isArabic ? "اختيار صورة" : "Choose Image", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Palette.gold)
            }
            HStack(spacing: 12) {
                Button { selectedImage = nil; scannerMessage = nil } label: {
                    Label(store.isArabic ? "مسح المعاينة" : "Clear", systemImage: "xmark.circle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Palette.goldDark)

                Button { Task { await processCurrent() } } label: {
                    Label(store.isArabic ? "تحليل الصورة" : "Analyze Image", systemImage: "sparkles").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.gold)
                .disabled(selectedImage == nil || processing)
            }
        }
        .font(.headline)
    }

    var corner: some View {
        Rectangle()
            .trim(from: 0, to: 0.5)
            .stroke(LinearGradient(colors: [Palette.goldLight, Palette.goldDark], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 60)
            .shadow(color: Palette.gold.opacity(0.45), radius: 7)
    }

    var pipelineView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Text(processor.stage.arabicMessage).font(.headline); Spacer(); Text("\(Int(processor.progress * 100))%").font(.caption.bold()).foregroundStyle(Palette.gold) }
                ProgressView(value: processor.progress).tint(Palette.gold)
            }
        }
    }

    func messageCard(_ text: String) -> some View {
        GlassCard(padding: 12) { Label(text, systemImage: "info.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(Palette.goldLight) }
    }

    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        selectedImage = image
        scannerMessage = store.isArabic ? "تم اختيار الصورة. يمكنك تحليلها الآن." : "Image selected. You can analyze it now."
    }

    func processCurrent() async {
        guard let image = selectedImage, let template = activeTemplate else { return }
        processing = true
        scannerMessage = store.isArabic ? "جارٍ قراءة الورقة وتصنيف الفقاعات..." : "Reading sheet and classifying bubbles..."
        let result = await processor.process(image: image, template: template)
        processing = false
        scannerMessage = nil
        review = result
    }
}

struct ReviewBox: Identifiable, Equatable { let id = UUID(); let result: OMRProcessingResult }

