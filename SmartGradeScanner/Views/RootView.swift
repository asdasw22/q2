import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var tab: SGTab = .scanner
    @State private var selectedExamForScan: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.pageBackground()

                VStack(spacing: 0) {
                    header

                    NeonDivider()
                        .padding(.horizontal)

                    TabView(selection: $tab) {
                        ScannerView(selectedExamId: selectedExamForScan)
                            .tag(SGTab.scanner)

                        ExamsView(onScan: { id in
                            selectedExamForScan = id
                            tab = .scanner
                        })
                        .tag(SGTab.exams)

                        StudentsView()
                            .tag(SGTab.students)

                        ClassroomsView()
                            .tag(SGTab.classrooms)

                        AnalyticsView()
                            .tag(SGTab.analytics)

                        TemplatesView()
                            .tag(SGTab.templates)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    bottomBar
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }

    var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Palette.goldLight,
                                Palette.indigo,
                                Palette.goldDark
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Palette.gold.opacity(0.24),
                        radius: 18,
                        y: 8
                    )

                Image(systemName: "checkmark.seal.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Palette.black)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("SmartGrade Scanner")
                    .font(
                        .system(
                            size: 24,
                            weight: .black,
                            design: .serif
                        )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Palette.goldLight,
                                Palette.gold
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(
                    store.isArabic
                    ? "Ù…Ø§Ø³Ø­ OMR Ø°ÙƒÙŠ â€¢ ØªØµØ­ÙŠØ­ ÙÙˆØ±ÙŠ â€¢ ØªØ­Ù„ÙŠÙ„Ø§Øª Ù…ØªÙ‚Ø¯Ù…Ø©"
                    : "Classic OMR â€¢ Instant grading â€¢ Golden dashboard"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.muted)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    store.isArabic.toggle()
                } label: {
                    Image(systemName: "globe")
                        .font(.title3.weight(.bold))
                        .frame(width: 42, height: 42)
                        .background(Palette.glass, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Palette.stroke, lineWidth: 1)
                        )
                }

                Button {
                    store.resetToDefaults()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3.weight(.bold))
                        .frame(width: 42, height: 42)
                        .background(Palette.glass, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Palette.stroke, lineWidth: 1)
                        )
                }
            }
            .foregroundStyle(Palette.text)
        }
        .padding(.horizontal)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    var bottomBar: some View {
        HStack(spacing: 7) {
            ForEach(SGTab.allCases) { item in
                tabButton(item)
            }
        }
        .padding(10)
        .background(LinearGradient(colors: [Palette.black2.opacity(0.96), Palette.obsidian.opacity(0.98)], startPoint: .top, endPoint: .bottom))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Palette.stroke),
            alignment: .top
        )
    }

    @ViewBuilder
    private func tabButton(_ item: SGTab) -> some View {
        let isSelected = tab == item

        Button {
            withAnimation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.78
                )
            ) {
                tab = item
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .bold))

                Text(item.title(ar: store.isArabic))
                    .font(.caption2.bold())
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(
                isSelected ? Palette.black : Palette.muted
            )
            .background {
                if isSelected {
                    LinearGradient(
                        colors: [
                            Palette.goldLight,
                            Palette.gold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                }
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    isSelected
                    ? Palette.goldLight.opacity(0.35)
                    : Color.clear,
                    lineWidth: 1
                )
            }
            .shadow(
                color: isSelected
                ? Palette.gold.opacity(0.24)
                : Color.clear,
                radius: 14,
                y: 8
            )
        }
        .buttonStyle(.plain)
    }
}

