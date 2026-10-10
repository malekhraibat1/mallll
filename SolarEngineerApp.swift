import SwiftUI

@main
struct SolarEngineerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("الرئيسية", systemImage: "sun.max.fill")
                }
            AboutView()
                .tabItem {
                    Label("حول", systemImage: "info.circle.fill")
                }
        }
        .tint(.orange)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.orange)

                Text("SolarEngineer")
                    .font(.largeTitle.bold())

                Text("مساعد مهندس الطاقة الشمسية")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("الرئيسية")
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("عن التطبيق") {
                    LabeledContent("الاسم", value: "SolarEngineer")
                    LabeledContent("الإصدار", value: "1.0.0")
                }
            }
            .navigationTitle("حول")
        }
    }
}