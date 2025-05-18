import SwiftUI
import CoreData

struct TagManagementView: View {
    let theme: ThemeMode
    @ObservedObject var viewModel: MemberViewModel
    @StateObject private var onboardingState = OnboardingState.shared
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: String?
    
    @State private var refreshTrigger = UUID()
    
    private var tagItems: [String] {
        // Get tags in reversed order so newest tags appear at the top
        viewModel.getAllCustomTags().reversed() 
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Add New Tag") {
                    NewTagInputView(
                        viewModel: viewModel,
                        theme: theme,
                        newTag: $newTag,
                        onTagAdded: {
                            withAnimation {
                                onboardingState.completeAddTag()
                                // Force immediate refresh
                                refreshTrigger = UUID()
                                // Post notification to update all views
                                NotificationCenter.default.post(name: NSNotification.Name("TagsUpdated"), object: nil)
                            }
                        }
                    )
                }
                .foregroundColor(theme.foregroundColor())
                
                // Show Custom Tags Section FIRST
                Section("Custom Tags") {
                    if tagItems.isEmpty {
                        Text("No custom tags")
                            .foregroundColor(theme.foregroundColor())
                    } else {
                        ForEach(tagItems, id: \.self) { tag in
                            HStack {
                                Image(systemName: tag.tagIcon)
                                    .foregroundStyle(theme.tintColor())
                                Text(tag)
                                    .foregroundColor(theme.foregroundColor())
                                Spacer()
                                Button {
                                    tagToDelete = tag
                                    showingDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .foregroundColor(theme.foregroundColor())
                
                // Then show Default Tags Section SECOND
                Section("Default Tags") {
                    ForEach(DefaultTags.sortedCases, id: \.self) { tag in
                        Button(action: {
                            withAnimation {
                                viewModel.addGlobalTag(tag.rawValue)
                                onboardingState.completeAddTag()
                                // Force immediate refresh
                                refreshTrigger = UUID()
                                // Post notification to update all views
                                NotificationCenter.default.post(name: NSNotification.Name("TagsUpdated"), object: nil)
                            }
                        }) {
                            HStack {
                                Image(systemName: tag.icon)
                                    .foregroundStyle(theme.tintColor())
                                Text(tag.rawValue)
                                    .foregroundColor(theme.foregroundColor())
                                Spacer()
                                if tagItems.contains(tag.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.tintColor())
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .foregroundColor(theme.foregroundColor())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.foregroundColor())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.foregroundColor())
                }
            }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled()
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TagsUpdated"))) { _ in
            // Force refresh the tag list whenever tags are updated
            refreshTrigger = UUID()
        }
        .id(refreshTrigger) // Force full view refresh when this changes
        .alert("Delete Tag", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let tag = tagToDelete {
                    withAnimation {
                        viewModel.removeGlobalTag(tag)
                    }
                }
            }
        } message: {
            if let tag = tagToDelete {
                Text("Are you sure you want to delete '\(tag)'? This will remove the tag from all members it is applied to.")
                    .foregroundColor(theme.foregroundColor())
            }
        }
    }
}

#Preview {
    NavigationView {
        TagManagementView(
            theme: .light,
            viewModel: MemberViewModel(context: PersistenceController.preview.container.viewContext)
        )
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
