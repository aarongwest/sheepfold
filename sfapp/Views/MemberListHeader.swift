import SwiftUI

struct MemberListHeader: View {
    let theme: ThemeMode
    let viewModel: MemberViewModel
    @Binding var showingFilters: Bool
    @Binding var selectedStatus: MemberStatus?
    @Binding var selectedTag: String?
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    @State private var refreshTrigger = UUID() // Add refresh trigger
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("FILTER/MESSAGE")
                    .font(.system(size: 12))
                    .foregroundColor(theme.foregroundColor())
                
                Spacer()
                
                Button {
                    showingFilters.toggle()
                } label: {
                    HStack(spacing: 4) {
                        if selectedStatus != nil || selectedTag != nil {
                            Text("Filtered")
                                .font(.system(size: 12))
                        }
                        Image(systemName: "line.3.horizontal.decrease.circle\(showingFilters ? ".fill" : "")")
                    }
                    .foregroundColor(theme.foregroundColor())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .padding(.top, 24)
            
            // Search field for members
            ZStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.foregroundColor().opacity(0.7))
                    
                    TextField("Search members by name", text: $searchText)
                        .foregroundColor(theme.foregroundColor())
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.foregroundColor().opacity(0.7))
                        }
                    }
                }
                .padding(10)
                .background(theme.backgroundColor().opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.foregroundColor().opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .contentShape(Rectangle()) // Make the entire area tappable
            .onTapGesture {
                // This will only trigger if the tap is outside the TextField
                if isSearchFocused {
                    isSearchFocused = false
                }
            }
            
            if showingFilters {
                FilterView(
                    theme: theme,
                    viewModel: viewModel,
                    selectedStatus: $selectedStatus,
                    selectedTag: $selectedTag
                )
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping anywhere in the header
                    isSearchFocused = false
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TagsUpdated"))) { _ in
            // Force refresh the view when tags are updated
            refreshTrigger = UUID()
            
            // This will ensure FilterView refreshes its tag list
            showingFilters = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingFilters = true
            }
        }
        .id(refreshTrigger) // Force view refresh when this changes
    }
}
