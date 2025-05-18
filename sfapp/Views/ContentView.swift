import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("themeMode") private var themeMode: Int = ThemeMode.dark.rawValue
    @StateObject private var viewModel: MemberViewModel
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var tutorialManager = TutorialManager.shared
    @State private var selectedMember: Member?
    @State private var selectedStatus: MemberStatus?
    @State private var selectedTag: String?
    @State private var searchText: String = ""
    @State private var showingFilters = true // Changed to true for open by default
    @State private var showPercentages = false
    @State private var refreshID = UUID()
    @State private var selectedTab: Int
    
    private var currentTheme: ThemeMode {
        ThemeMode(rawValue: themeMode) ?? .dark
    }
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MemberViewModel(context: context))
        
        // Always start at the home tab
        _selectedTab = State(initialValue: 0)
        
        // Reset the notifications flag if it exists
        if UserDefaults.standard.bool(forKey: "showNotifications") {
            UserDefaults.standard.set(false, forKey: "showNotifications")
        }
        
        // Disable split view behavior and sidebar on iPad
        if #available(iOS 14.0, *) {
            UINavigationBar.appearance().isTranslucent = false
            
            // Disable sidebar on iPad
            if let splitViewController = UIApplication.shared.windows.first?.rootViewController as? UISplitViewController {
                splitViewController.preferredDisplayMode = .oneBesideSecondary
                splitViewController.presentsWithGesture = false
            }
            
            // Hide the sidebar button on iPad
            UINavigationBar.appearance().prefersLargeTitles = false
        }
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Member.firstName, ascending: true)],
        animation: .default)
    private var members: FetchedResults<Member>
    
    private var filteredMembers: [Member] {
        members.filter { member in
            var shouldInclude = true
            
            if let selectedStatus = selectedStatus {
                shouldInclude = member.status == selectedStatus.rawValue
            }
            
            if shouldInclude, let selectedTag = selectedTag {
                shouldInclude = member.tagArray.contains(selectedTag)
            }
            
            // Filter by search text if not empty
            if shouldInclude && !searchText.isEmpty {
                let fullName = "\(member.firstName ?? "") \(member.lastName ?? "")"
                shouldInclude = fullName.lowercased().contains(searchText.lowercased())
            }
            
            return shouldInclude
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationView {
                    VStack(spacing: 0) {
                        // Content Area
                        ZStack {
                            // Home View
                            if selectedTab == 0 {
                                VStack(spacing: 0) {
                                    // Fixed Header
                                    NavigationHeader(
                                        theme: currentTheme,
                                        viewModel: viewModel,
                                        themeMode: $themeMode
                                    )
                                    .background(currentTheme.backgroundColor())
                                    
                                    // Scrollable Content
                                    ScrollView {
                                        VStack(spacing: 0) {
                                            DashboardView(
                                                viewModel: viewModel,
                                                theme: currentTheme,
                                                showPercentages: $showPercentages,
                                                selectedStatus: $selectedStatus
                                            )
                                            .background(currentTheme.backgroundColor())
                                            .padding(.bottom, 16)  // Add padding between dashboard and header
                                            
                                            MemberListHeader(
                                                theme: currentTheme,
                                                viewModel: viewModel,
                                                showingFilters: $showingFilters,
                                                selectedStatus: $selectedStatus,
                                                selectedTag: $selectedTag,
                                                searchText: $searchText
                                            )
                                            .background(currentTheme.backgroundColor())
                                            
                                            MemberListView(
                                                theme: currentTheme,
                                                members: filteredMembers,
                                                refreshID: refreshID,
                                                selectedMember: $selectedMember
                                            )
                                        }
                                        .padding(.bottom, 50)
                                        .contentShape(Rectangle()) // Make the entire area tappable
                                        .onTapGesture {
                                            // Dismiss keyboard when tapping anywhere in the content
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }
                                    .background(currentTheme.backgroundColor())
                                }
                            }
                            
                            // Feedback View
                            if selectedTab == 1 {
                                FeedbackView(theme: currentTheme, selectedTab: $selectedTab)
                            }
                            
                            // Info View
                            if selectedTab == 2 {
                                InfoView(theme: currentTheme)
                            }
                            
                            // Treasure View
                            if selectedTab == 3 {
                                TreasureView(theme: currentTheme, viewModel: viewModel)
                            }
                            
                            // Share View
                            if selectedTab == 4 {
                                ShareView(theme: currentTheme)
                            }
                        }
                        .background(currentTheme.backgroundColor())
                        .frame(width: geometry.size.width, height: geometry.size.height - 49) // Adjust for tab bar
                        
                        // Custom Tab Bar
                        Divider()
                        HStack(spacing: 0) {
                            ForEach(0..<5) { index in
                                Button {
                                    withAnimation {
                                        selectedTab = index
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: tabIcon(for: index))
                                            .font(.system(size: 20))
                                        
                                        Text(tabTitle(for: index))
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(selectedTab == index ? (currentTheme.isColorful ? .blue : currentTheme.iconColor()) : .gray)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .frame(height: 49)
                        .background(currentTheme.backgroundColor())
                    }
                    .background(currentTheme.backgroundColor())
                    .navigationBarHidden(true)
                    .ignoresSafeArea(.keyboard)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
                // Tutorial overlay - completely disabled for now
                // Will be revisited in a future update
                if false { // Never show the tutorial
                    TutorialOverlayView(theme: currentTheme)
                        .zIndex(100)
                }
            }
            .sheet(item: $selectedMember) { member in
                NavigationView {
                    MemberDetailView(
                        viewModel: viewModel,
                        member: member,
                        theme: currentTheme
                    )
                }
                .navigationViewStyle(.stack)
                .onDisappear {
                    refreshID = UUID()
                }
            }
            .onAppear {
                // Request notification permissions if needed
                Task {
                    let notificationManager = NotificationManager.shared
                    if !notificationManager.hasPermission {
                        _ = await notificationManager.requestPermission()
                    }
                }
                
                // We've removed the automatic tutorial trigger here
                // The tutorial will only be triggered from the "How to Use" section
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Force refresh notifications when app becomes active
                notificationManager.objectWillChange.send()
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.showNotificationView)) { _ in
                withAnimation {
                    selectedTab = 0  // Switch to Home tab instead of the removed notifications tab
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowMemberDetail"))) { notification in
                if let member = notification.userInfo?["member"] as? Member {
                    selectedMember = member
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToHomeTab"))) { _ in
                withAnimation {
                    selectedTab = 0  // Switch to Home tab
                }
            }
            .preferredColorScheme(currentTheme.isDark ? .dark : .light)
            .tint(currentTheme.tintColor())
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house"
        case 1: return "heart.text.square"
        case 2: return "info.circle"
        case 3: return "crown.fill" // Treasure icon
        case 4: return "square.and.arrow.up" // Share icon
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Feedback"
        case 2: return "About"
        case 3: return "Treasure"
        case 4: return "Share"
        default: return ""
        }
    }
}

#Preview {
    ContentView(context: PersistenceController.preview.container.viewContext)
}
