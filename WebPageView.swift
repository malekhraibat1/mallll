import SwiftUI
import WebKit

// ═══════════════════════════════════════════════════════════
// MARK: - SITE CONFIG
// ═══════════════════════════════════════════════════════════

enum AppSite {
    static let mainURL = "https://maleksolar.vercel.app"
    static let mainTitle = "Maleksolar"
    static let mainDescription = "موقعنا الرسمي"
}

// ═══════════════════════════════════════════════════════════
// MARK: - WEB VIEW
// ═══════════════════════════════════════════════════════════

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String
    @Binding var progress: Double

    @Binding var commandGoBack: Bool
    @Binding var commandGoForward: Bool
    @Binding var commandReload: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.isOpaque = true
        webView.backgroundColor = UIColor.systemBackground

        context.coordinator.observeProgress(webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if commandGoBack {
            if webView.canGoBack { webView.goBack() }
            DispatchQueue.main.async { commandGoBack = false }
        }
        if commandGoForward {
            if webView.canGoForward { webView.goForward() }
            DispatchQueue.main.async { commandGoForward = false }
        }
        if commandReload {
            webView.reload()
            DispatchQueue.main.async { commandReload = false }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var progressObservation: NSKeyValueObservation?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func observeProgress(_ webView: WKWebView) {
            progressObservation = webView.observe(
                \.estimatedProgress,
                options: [.new]
            ) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.progress = webView.estimatedProgress
                }
            }
        }

        func webView(_ webView: WKWebView,
                     didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                if let title = webView.title, !title.isEmpty {
                    self.parent.pageTitle = title
                }
            }
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - WEB PAGE VIEW
// ═══════════════════════════════════════════════════════════

struct WebPageView: View {
    let urlString: String
    var title: String = "الصفحة"

    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var pageTitle = ""
    @State private var progress: Double = 0
    @State private var showingShare = false

    @State private var commandGoBack = false
    @State private var commandGoForward = false
    @State private var commandReload = false

    @Environment(\.presentationMode) var presentationMode

    private var url: URL {
        URL(string: urlString) ?? URL(string: "https://maleksolar.vercel.app")!
    }

    private var displayTitle: String {
        if !pageTitle.isEmpty && pageTitle != "Vercel" { return pageTitle }
        return title
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .frame(height: 3)
            } else {
                Rectangle().fill(Color.clear).frame(height: 3)
            }

            ZStack {
                WebView(
                    url: url,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    pageTitle: $pageTitle,
                    progress: $progress,
                    commandGoBack: $commandGoBack,
                    commandGoForward: $commandGoForward,
                    commandReload: $commandReload
                )

                if isLoading && progress < 0.1 {
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("جاري التحميل...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            HStack(spacing: 0) {
                toolbarButton(icon: "chevron.right", enabled: canGoBack) {
                    commandGoBack = true
                }
                Spacer()
                toolbarButton(icon: "chevron.left", enabled: canGoForward) {
                    commandGoForward = true
                }
                Spacer()
                toolbarButton(icon: "arrow.clockwise", enabled: true) {
                    commandReload = true
                }
                Spacer()
                toolbarButton(icon: "house.fill", enabled: true) {
                    commandReload = true
                }
                Spacer()
                toolbarButton(icon: "safari", enabled: true) {
                    if let u = URL(string: urlString) {
                        UIApplication.shared.open(u)
                    }
                }
                Spacer()
                toolbarButton(icon: "square.and.arrow.up", enabled: true) {
                    showingShare = true
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemBackground))
        }
        .navigationBarTitle(displayTitle, displayMode: .inline)
        .sheet(isPresented: $showingShare) {
            if let u = URL(string: urlString) {
                ShareSheet(items: [u])
            }
        }
    }

    func toolbarButton(icon: String,
                       enabled: Bool,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(enabled ? .orange : .gray.opacity(0.4))
                .frame(width: 42, height: 42)
        }
        .disabled(!enabled)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - SHARE SHEET
// ═══════════════════════════════════════════════════════════

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// ═══════════════════════════════════════════════════════════
// MARK: - PAGES LIST
// ═══════════════════════════════════════════════════════════

struct PagesListView: View {
    var body: some View {
        List {
            Section(header: Text("الموقع الرسمي")) {
                NavigationLink(destination: WebPageView(
                    urlString: AppSite.mainURL,
                    title: AppSite.mainTitle
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(AppSite.mainTitle)
                                .font(.subheadline).fontWeight(.semibold)
                            Text("maleksolar.vercel.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(header: Text("صفحات مهمة")) {
                linkRow("التوثيق", "book.fill", "https://www.apple.com/swift/")
                linkRow("حاسبة PVGIS", "safari.fill",
                        "https://re.jrc.ec.europa.eu/pvg_tools/en/")
                linkRow("الدعم الفني", "questionmark.circle.fill",
                        "https://github.com/malekhraibat1/mallll/issues")
                linkRow("سياسة الخصوصية", "lock.shield.fill",
                        "https://www.apple.com/legal/privacy/")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("الصفحات والروابط", displayMode: .inline)
    }

    func linkRow(_ title: String, _ icon: String, _ url: String) -> some View {
        NavigationLink(destination: WebPageView(urlString: url, title: title)) {
            Label(title, systemImage: icon)
        }
    }
}
