import SwiftUI

struct InfoView: View {
    let theme: ThemeMode
    @State private var selectedTab = 0
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo and Version
            VStack(spacing: 4) {
                Image("sheepfold-logo")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(theme.tintColor())
                
                Text("Version 1.5.0")
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(theme.backgroundColor())
            
            // Tab Selector
            HStack(spacing: 0) {
                InfoTabButton(
                    title: "About",
                    systemImage: "info.circle",
                    isSelected: selectedTab == 0,
                    theme: theme
                ) {
                    withAnimation {
                        selectedTab = 0
                    }
                }
                
                InfoTabButton(
                    title: "How to Use",
                    systemImage: "book",
                    isSelected: selectedTab == 1,
                    theme: theme
                ) {
                    withAnimation {
                        selectedTab = 1
                    }
                }
                
                InfoTabButton(
                    title: "Changelog",
                    systemImage: "list.bullet.clipboard",
                    isSelected: selectedTab == 2,
                    theme: theme
                ) {
                    withAnimation {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Content
            TabView(selection: $selectedTab) {
                AboutView(theme: theme)
                    .tag(0)
                
                HowToUseView(theme: theme)
                    .tag(1)
                
                ChangelogView(theme: theme)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(theme.backgroundColor())
        .onAppear {
            if !hasAppeared {
                selectedTab = 0
                hasAppeared = true
            }
        }
    }
}

struct InfoTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let theme: ThemeMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? theme.backgroundColor(elevated: true) : Color.clear)
            .foregroundColor(isSelected ? (theme.isColorful ? .blue : theme.iconColor()) : theme.foregroundColor())
            .cornerRadius(8)
        }
    }
}

struct AboutView: View {
    let theme: ThemeMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About This App")
                    .font(.headline)
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal)
                
                Text("1. Proactive Member Care - Regular check-in system keeps leaders engaged with their members, and birthday tracking helps maintain personal connections.\n\n2. Organized Member Management - Centralized system for tracking member information, tag-based organization for flexible grouping, status tracking to understand where each member is, and easy access to member history and notes.\n\n3. Lost members often leave silently without expressing needs. Sheepfold's systematic follow-up prevents accidental neglect. The real question isn't 'Can we afford a member care system?' but 'Can we afford to lose members because we lack one?'\n\n4. Just one retained member's monthly giving typically exceeds the subscription cost.\n\n5. Saving 1-2 hours of leadership time per month justifies the investment.\n\n6. Preventing one member from falling away covers a year's subscription.\n\n7. The peace of mind knowing no one is forgotten is invaluable.")
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal)
                
                // Links Section
                VStack(spacing: 16) {
                    Link(destination: URL(string: "https://zygur.com/labs/sheepfold")!) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(theme.foregroundColor())
                            Text("More Information")
                                .foregroundColor(theme.foregroundColor())
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(theme.foregroundColor())
                        }
                        .padding()
                        .background(theme.backgroundColor(elevated: true))
                        .cornerRadius(8)
                    }
                    
                    Link(destination: URL(string: "https://zygur.com/labs/sheepfold")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(theme.foregroundColor())
                            Text("Privacy Policy")
                                .foregroundColor(theme.foregroundColor())
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(theme.foregroundColor())
                        }
                        .padding()
                        .background(theme.backgroundColor(elevated: true))
                        .cornerRadius(8)
                    }
                    
                    Link(destination: URL(string: "https://zygur.com/labs/sheepfold")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(theme.foregroundColor())
                            Text("Terms of Use")
                                .foregroundColor(theme.foregroundColor())
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(theme.foregroundColor())
                        }
                        .padding()
                        .background(theme.backgroundColor(elevated: true))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Text("© 2024 Sheepfold App")
                    .font(.footnote)
                    .foregroundColor(theme.foregroundColor())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
            }
            .padding(.vertical)
        }
        .background(theme.backgroundColor())
    }
}

struct HowToUseView: View {
    let theme: ThemeMode
    @StateObject private var tutorialManager = TutorialManager.shared
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Getting Started")
                    .font(.headline)
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal)
                
                Text("1. Add members quickly using the plus icon under Dashboard.\n\n2. Visualize your flock at a glance with powerful status tracking (Active, At-Risk, Critical, or Inactive).\n\n3. Create custom tags to organize and group members your way - perfect for ministry teams, small groups, or any category you need.\n\n4. Track conversations and prayer needs with the notes feature.\n\n5. Maintain consistent follow-ups with the status tracking system.\n\n6. Instantly reach out to individuals or groups - send messages to everyone with a specific tag or status.\n\n7. Access detailed member profiles with one tap to view history, add notes, or make contact.")
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal)
                
                // Tutorial button removed - will be revisited in a future update
            }
            .padding(.vertical)
        }
        .background(theme.backgroundColor())
    }
}

struct ChangelogView: View {
    let theme: ThemeMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Version 1.5.0
                Group {
                    Text("Version 1.5.0")
                        .font(.headline)
                        .foregroundColor(theme.foregroundColor())
                    
                    Text("May 2025")
                        .font(.subheadline)
                        .foregroundColor(theme.foregroundColor())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Fixed tag-filtered contacts not appearing in SMS/email 'to' field")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Custom tags now appear at the beginning of tag lists for easier access")
                            .foregroundColor(theme.foregroundColor())
                        Text("• New tags now display immediately when created without requiring view refresh")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Fixed feedback form submission errors")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Various performance improvements and bug fixes")
                            .foregroundColor(theme.foregroundColor())
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Version 1.4.0
                Group {
                    Text("Version 1.4.0")
                        .font(.headline)
                        .foregroundColor(theme.foregroundColor())
                    
                    Text("February 2025")
                        .font(.subheadline)
                        .foregroundColor(theme.foregroundColor())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Added advanced filtering capabilities")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Improved member search functionality")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Enhanced tag management system")
                            .foregroundColor(theme.foregroundColor())
                        Text("• UI/UX refinements")
                            .foregroundColor(theme.foregroundColor())
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Version 1.3.0
                Group {
                    Text("Version 1.3.0")
                        .font(.headline)
                        .foregroundColor(theme.foregroundColor())
                    
                    Text("December 2024")
                        .font(.subheadline)
                        .foregroundColor(theme.foregroundColor())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Added multiple theme options (light, dark, colorful)")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Improved UI for better visual hierarchy")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Enhanced accessibility features")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Performance optimizations")
                            .foregroundColor(theme.foregroundColor())
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Version 1.2.0
                Group {
                    Text("Version 1.2.0")
                        .font(.headline)
                        .foregroundColor(theme.foregroundColor())
                    
                    Text("October 2024")
                        .font(.subheadline)
                        .foregroundColor(theme.foregroundColor())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Added reward/treasure system for consistent member care")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Implemented share functionality")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Streamlined interface for better usability")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Removed backup/restore in favor of cloud sync")
                            .foregroundColor(theme.foregroundColor())
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Version 1.1.0
                Group {
                    Text("Version 1.1.0")
                        .font(.headline)
                        .foregroundColor(theme.foregroundColor())
                    
                    Text("July 2024")
                        .font(.subheadline)
                        .foregroundColor(theme.foregroundColor())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Improved performance and stability")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Enhanced member management workflows")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Bug fixes and optimizations")
                            .foregroundColor(theme.foregroundColor())
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Version 1.0.0
                Group {
                    Text("Version 1.0.0")
                        .font(.headline)
                        .foregroundColor(theme.foregroundColor())
                    
                    Text("May 2024 - Initial Release")
                        .font(.subheadline)
                        .foregroundColor(theme.foregroundColor())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Complete member management system")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Custom tagging and categorization")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Prayer and outreach tracking")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Event tracking system")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Contact integration")
                            .foregroundColor(theme.foregroundColor())
                        Text("• Backup and restore functionality")
                            .foregroundColor(theme.foregroundColor())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(theme.backgroundColor())
    }
}

#Preview {
    InfoView(theme: .light)
}
