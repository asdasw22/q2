import SwiftUI
import PhotosUI
import AVFoundation

struct ScannerView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @StateObject private var processor = OMRProcessor()
    @StateObject private var camera = CameraController()
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
                heroCard
                cameraStage
                if processing { pipelineView }
                HStack {
                    MetricTile(title: store.isArabic ? "القوالب" : "Templates", value: "\(store.templates.count)", icon: "square.grid.3x3.fill", tint: Palette.cyan)
                    MetricTile(title: store.isArabic ? "النتائج" : "Results", value: "\(store.results.count)", icon: "checklist.checked", tint: Palette.emerald)
                }
            }
            .padding()
        }
        .pageBackground()
        .onAppear { activeExamId = selectedExamId ?? store.exams.first?.id ?? "" }
        .onDisappear { camera.stop() }
        .onChange(of: selectedPhoto) { _, newItem in Task { await loadPhoto(newItem) } }
        .onReceive(camera.$capturedImage.compactMap { $0 }) { image in
            selectedImage = image
            Task { await processCurrent() }
        }
        .sheet(item: Binding(get: { review.map { ReviewBox(result: $0) } }, set: { if $0 == nil { review = nil } })) { box in
            if let exam = activeExam { ScanReviewView(omr: box.result, exam: exam) { result in store.saveResult(result); review = nil } onDiscard: { review = nil } }
        }
    }

    var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Label(store.isArabic ? "ماسح ورقة الإجابة الذكي" : "Smart OMR Scanner", systemImage: "camera.metering.matrix")
                            .font(.title2.bold())
                            .foregroundStyle(Palette.text)
                        Text(store.isArabic ? "صوّر الورقة مباشرة أو ارفعها من المعرض. التطبيق يقرأ رقم الطالب، يصنف الفقاعات، ويفتح مراجعة قبل الحفظ." : "Capture or import a sheet. The app decodes student ID, classifies bubbles and opens a teacher review screen.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.title.bold())
                        .foregroundStyle(Palette.cyan)
                        .padding(12)
                        .background(Palette.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                }
                Picker(store.isArabic ? "الامتحان النشط" : "Active Exam", selection: $activeExamId) {
                    ForEach(store.exams) { Text("\($0.name) (\($0.questions.count)Q)").tag($0.id) }
                }
                .pickerStyle(.menu)
                .tint(Palette.cyan)
            }
        }
    }

    var cameraStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(LinearGradient(colors: [Color.black, Palette.surface, Palette.bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 34).stroke(LinearGradient(colors: [Palette.cyan.opacity(0.55), Palette.indigo.opacity(0.25), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.4))
                .shadow(color: Palette.cyan.opacity(0.12), radius: 28, y: 12)

            if camera.authorizationStatus == .authorized && camera.isSessionRunning && selectedImage == nil {
                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .padding(8)
            } else if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .padding(8)
            } else {
                inactiveCameraContent
            }

            scanOverlay
            controlsOverlay
        }
        .frame(minHeight: 530)
    }

    var inactiveCameraContent: some View {
        VStack(spacing: 16) {
            Image(systemName: camera.authorizationStatus == .denied ? "camera.badge.ellipsis" : "doc.viewfinder")
                .font(.system(size: 62, weight: .light))
                .foregroundStyle(LinearGradient(colors: [Palette.cyan, Palette.violet], startPoint: .top, endPoint: .bottom))
            Text(camera.errorMessage ?? (store.isArabic ? "الكاميرا غير مفعلة — اضغط تشغيل الكاميرا لطلب الإذن" : "Camera inactive — tap Start Camera to request permission"))
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.text)
                .padding(.horizontal, 26)
            Text(store.isArabic ? "يمكنك أيضًا اختيار صورة جاهزة من المعرض" : "You can also import a prepared image from Photos")
                .font(.caption)
                .foregroundStyle(Palette.muted)
        }
    }

    var scanOverlay: some View {
        VStack {
            HStack { corner; Spacer(); corner.rotationEffect(.degrees(90)) }
            Spacer()
            RoundedRectangle(cornerRadius: 24)
                .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 8]))
                .foregroundStyle(Palette.cyan.opacity(0.55))
                .frame(maxWidth: 300, maxHeight: 420)
                .overlay(Text("A4 OMR").font(.caption.bold()).foregroundStyle(Palette.cyan).padding(8).background(Color.black.opacity(0.42), in: Capsule()).offset(y: -215))
            Spacer()
            HStack { corner.rotationEffect(.degrees(-90)); Spacer(); corner.rotationEffect(.degrees(180)) }
        }
        .padding(32)
        .allowsHitTesting(false)
    }

    var controlsOverlay: some View {
        VStack {
            HStack {
                statusBadge
                Spacer()
                if selectedImage != nil { Button { selectedImage = nil; camera.requestPermissionAndStart() } label: { Label("Live", systemImage: "video.fill") }.buttonStyle(.borderedProminent).tint(Palette.cyan) }
            }
            .padding(18)
            Spacer()
            VStack(spacing: 12) {
                if let err = camera.errorMessage { Text(err).font(.caption.weight(.semibold)).foregroundStyle(Palette.amber).padding(.horizontal) }
                HStack(spacing: 12) {
                    Button { camera.requestPermissionAndStart() } label: { Label(store.isArabic ? "تشغيل الكاميرا" : "Start Camera", systemImage: "video.fill").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.indigo)
                    PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(store.isArabic ? "المعرض" : "Photos", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity) }
                        .buttonStyle(.bordered)
                        .tint(Palette.cyan)
                }
                HStack(spacing: 12) {
                    Button { camera.capturePhoto() } label: { Label(store.isArabic ? "التقاط ومسح" : "Capture & Scan", systemImage: "camera.aperture").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.emerald)
                        .disabled(camera.authorizationStatus != .authorized || !camera.isSessionRunning || processing)
                    Button { Task { await processCurrent() } } label: { Label(store.isArabic ? "مسح الصورة" : "Scan Image", systemImage: "sparkles").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.violet)
                        .disabled(selectedImage == nil || processing)
                }
            }
            .font(.headline)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Palette.stroke, lineWidth: 1))
            .padding(14)
        }
    }

    var statusBadge: some View {
        let text = camera.authorizationStatus == .authorized ? (camera.isSessionRunning ? "LIVE" : "READY") : "PERMISSION"
        return Text(text)
            .font(.caption.bold())
            .foregroundStyle(camera.authorizationStatus == .authorized ? Palette.emerald : Palette.amber)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.42), in: Capsule())
            .overlay(Capsule().stroke((camera.authorizationStatus == .authorized ? Palette.emerald : Palette.amber).opacity(0.42), lineWidth: 1))
    }

    var corner: some View {
        Rectangle()
            .trim(from: 0, to: 0.5)
            .stroke(LinearGradient(colors: [Palette.cyan, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .frame(width: 58, height: 58)
            .shadow(color: Palette.cyan.opacity(0.65), radius: 8)
    }

    var pipelineView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Text(processor.stage.arabicMessage).font(.headline); Spacer(); Text("\(Int(processor.progress * 100))%").font(.caption.bold()).foregroundStyle(Palette.cyan) }
                ProgressView(value: processor.progress).tint(Palette.cyan)
            }
        }
    }

    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        selectedImage = image
    }

    func processCurrent() async {
        guard let image = selectedImage, let template = activeTemplate else { return }
        processing = true
        let result = await processor.process(image: image, template: template)
        processing = false
        review = result
    }
}

struct ReviewBox: Identifiable, Equatable { let id = UUID(); let result: OMRProcessingResult }

