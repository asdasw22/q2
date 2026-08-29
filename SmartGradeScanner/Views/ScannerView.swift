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

    var activeExam: Exam? {
        store.exams.first { $0.id == (activeExamId.isEmpty ? (selectedExamId ?? "") : activeExamId) } ?? store.exams.first
    }

    var activeTemplate: TemplateDefinition? {
        guard let exam = activeExam else { return nil }
        return store.templates.first { $0.id == exam.templateId }?.definition ?? store.templates.first?.definition
    }

    var canUseDocumentScanner: Bool { VNDocumentCameraViewController.isSupported }
    var canUseSystemCamera: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        NavigationStack {
            ZStack {
                cameraBackdrop

                VStack {
                    topBar
                    Spacer()
                    scanGuide
                    Spacer()
                    if processing { processingBadge }
                    if let scannerMessage { messageBadge(scannerMessage) }
                    controls
                }
            }
            .navigationTitle(store.isArabic ? "المسح" : "Scan")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { activeExamId = selectedExamId ?? store.exams.first?.id ?? "" }
        .onChange(of: selectedPhoto) { _, newItem in Task { await loadPhoto(newItem) } }
        .fullScreenCover(isPresented: $showDocumentScanner) {
            DocumentScannerView { images in
                showDocumentScanner = false
                guard let image = images.first else {
                    scannerMessage = store.isArabic ? "لم يتم التقاط أي صفحة." : "No page captured."
                    return
                }
                selectedImage = image
                scannerMessage = store.isArabic ? "تم التقاط المستند" : "Document captured"
                Task { await processCurrent() }
            } onCancel: {
                showDocumentScanner = false
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showSystemCamera) {
            SystemCameraView { image in
                showSystemCamera = false
                selectedImage = image
                scannerMessage = store.isArabic ? "تم التقاط الصورة" : "Photo captured"
                Task { await processCurrent() }
            } onCancel: {
                showSystemCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(item: Binding(get: { review.map { ReviewBox(result: $0) } }, set: { if $0 == nil { review = nil } })) { box in
            if let exam = activeExam {
                ScanReviewView(omr: box.result, exam: exam) { result in
                    store.saveResult(result)
                    review = nil
                } onDiscard: {
                    review = nil
                }
            }
        }
    }

    private var cameraBackdrop: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.28).ignoresSafeArea())
            } else {
                LinearGradient(colors: [.black, .black.opacity(0.86), .gray.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 96, weight: .thin))
                    .foregroundStyle(.white.opacity(0.16))
            }
        }
    }

    private var topBar: some View {
        HStack {
            Menu {
                Picker(store.isArabic ? "الاختبار" : "Exam", selection: $activeExamId) {
                    ForEach(store.exams) { exam in
                        Text("\(exam.name) (\(exam.questions.count)Q)").tag(exam.id)
                    }
                }
            } label: {
                Label(activeExam?.name ?? (store.isArabic ? "مسح سريع" : "Quick Scan"), systemImage: "doc.text")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .tint(.white)

            Spacer()

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .tint(.white)
        }
        .padding()
    }

    private var scanGuide: some View {
        RoundedRectangle(cornerRadius: 22)
            .stroke(processing ? .orange : .white, style: StrokeStyle(lineWidth: 3, dash: [10]))
            .frame(maxWidth: 430)
            .aspectRatio(0.707, contentMode: .fit)
            .padding(28)
            .overlay(alignment: .bottom) {
                Text(guideText)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(.bottom, 45)
            }
    }

    private var guideText: String {
        if processing { return processor.stage.arabicMessage }
        if selectedImage != nil { return store.isArabic ? "الصورة جاهزة للتحليل" : "Image ready to scan" }
        return store.isArabic ? "ضع ورقة الإجابة داخل الإطار" : "Place the answer sheet inside the frame"
    }

    private var controls: some View {
        HStack(spacing: 28) {
            Button {
                if canUseDocumentScanner {
                    showDocumentScanner = true
                } else {
                    scannerMessage = store.isArabic ? "ماسح المستندات غير مدعوم" : "Document scanner unavailable"
                }
            } label: {
                Label(store.isArabic ? "Document" : "Document", systemImage: "doc.viewfinder")
            }
            .buttonStyle(.borderedProminent)
            .disabled(processing)

            Button {
                if selectedImage != nil {
                    Task { await processCurrent() }
                } else if canUseSystemCamera {
                    showSystemCamera = true
                } else {
                    scannerMessage = store.isArabic ? "الكاميرا غير متاحة" : "Camera unavailable"
                }
            } label: {
                Image(systemName: selectedImage == nil ? "circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .overlay { Circle().stroke(.black.opacity(0.3), lineWidth: 2) }
            }
            .disabled(processing)

            Button {
                selectedImage = nil
                scannerMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .frame(width: 90)
                    .foregroundStyle(selectedImage == nil ? .white.opacity(0.35) : .white)
            }
            .disabled(selectedImage == nil || processing)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
    }

    private var processingBadge: some View {
        HStack(spacing: 10) {
            ProgressView(value: processor.progress)
                .tint(.orange)
                .frame(width: 120)
            Text("\(Int(processor.progress * 100))%")
                .font(.caption.monospacedDigit().bold())
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(.black.opacity(0.6), in: Capsule())
    }

    private func messageBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.6), in: Capsule())
    }

    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        selectedImage = image
        scannerMessage = store.isArabic ? "تم اختيار الصورة" : "Image selected"
    }

    func processCurrent() async {
        guard let image = selectedImage, let template = activeTemplate else { return }
        processing = true
        scannerMessage = nil
        let result = await processor.process(image: image, template: template)
        processing = false
        review = result
    }
}

struct ReviewBox: Identifiable, Equatable { let id = UUID(); let result: OMRProcessingResult }
