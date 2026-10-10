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
        .accentColor(.orange)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.orange)

                Text("SolarEngineer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("مساعد مهندس الطاقة الشمسية")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationBarTitle("الرئيسية", displayMode: .large)
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("عن التطبيق")) {
                    HStack {
                        Text("الاسم")
                        Spacer()
                        Text("SolarEngineer")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("حول", displayMode: .large)
        }
    }
}
