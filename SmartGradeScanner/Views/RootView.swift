import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var tab: SGTab = .scanner
    @State private var selectedExamForScan: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                TabView(selection: $tab) {
                    ScannerView(selectedExamId: selectedExamForScan).tag(SGTab.scanner)
                    ExamsView(onScan: { id in selectedExamForScan = id; tab = .scanner }).tag(SGTab.exams)
                    StudentsView().tag(SGTab.students)
                    ClassroomsView().tag(SGTab.classrooms)
                    AnalyticsView().tag(SGTab.analytics)
                    TemplatesView().tag(SGTab.templates)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                bottomBar
            }
            .pageBackground()
            .navigationBarHidden(true)
        }
    }

    var header: some View {
        HStack(spacing: 14) {
            ZStack { RoundedRectangle(cornerRadius: 18).fill(Palette.indigo); Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(.white) }.frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text("SmartGrade Scanner").font(.title2.bold()).foregroundStyle(Palette.slate900)
                Text(store.isArabic ? "ماسح أوراق إجابات OMR محلي ومتقدم" : "Offline advanced OMR answer sheet scanner").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { store.isArabic.toggle() } label: { Image(systemName: "globe").font(.title3).padding(10).background(.white, in: Circle()) }
            Button { store.resetToDefaults() } label: { Image(systemName: "arrow.clockwise").font(.title3).padding(10).background(.white, in: Circle()) }
        }.padding(.horizontal).padding(.top, 12).padding(.bottom, 8)
    }

    var bottomBar: some View {
        HStack {
            ForEach(SGTab.allCases) { item in
                Button { withAnimation(.spring) { tab = item } } label: {
                    VStack(spacing: 4) { Image(systemName: item.icon).font(.system(size: 18, weight: .semibold)); Text(item.title(ar: store.isArabic)).font(.caption2.bold()).lineLimit(1) }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .foregroundStyle(tab == item ? Palette.indigo : .secondary)
                        .background(tab == item ? Palette.indigo.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
            }
        }.padding(10).background(.white.opacity(0.96)).overlay(Rectangle().frame(height: 1).foregroundStyle(.black.opacity(0.06)), alignment: .top)
    }
}

