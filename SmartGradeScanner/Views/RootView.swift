import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var tab: SGTab = .scanner
    @State private var selectedExamForScan: String?

    var body: some View {
        TabView(selection: $tab) {
            ScannerView(selectedExamId: selectedExamForScan)
                .tabItem { Label(store.isArabic ? "المسح" : "Scan", systemImage: "camera.viewfinder") }
                .tag(SGTab.scanner)

            ExamsView(onScan: { id in
                selectedExamForScan = id
                tab = .scanner
            })
            .tabItem { Label(store.isArabic ? "الاختبارات" : "Exams", systemImage: "list.clipboard.fill") }
            .tag(SGTab.exams)

            StudentsView()
                .tabItem { Label(store.isArabic ? "الطلاب" : "Students", systemImage: "person.3.fill") }
                .tag(SGTab.students)

            ClassroomsView()
                .tabItem { Label(store.isArabic ? "الصفوف" : "Classes", systemImage: "person.2.fill") }
                .tag(SGTab.classrooms)

            AnalyticsView()
                .tabItem { Label(store.isArabic ? "الإحصائيات" : "Statistics", systemImage: "chart.bar.fill") }
                .tag(SGTab.analytics)

            TemplatesView()
                .tabItem { Label(store.isArabic ? "القوالب" : "Templates", systemImage: "square.grid.3x3.fill") }
                .tag(SGTab.templates)
        }
        .tint(.accentColor)
    }
}
