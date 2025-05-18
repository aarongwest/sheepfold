//
//  NewTagInputView.swift
//  sfapp
//
//  Created by Aaron West on 11/27/24.
//

import SwiftUI

struct NewTagInputView: View {
    @ObservedObject var viewModel: MemberViewModel
    let theme: ThemeMode
    @Binding var newTag: String
    var onTagAdded: (() -> Void)?
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmedTag.isEmpty && DefaultTags.fromString(trimmedTag) == nil else { return }

        // Clear input first to prevent UI lag
        newTag = ""
        
        // Then add the tag and notify parent
        viewModel.addGlobalTag(trimmedTag)
        
        // Manually dismiss the keyboard to show the newly added tag
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Notify parent
        onTagAdded?()
        
        // Explicitly post a notification to update all observers immediately
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("TagsUpdated"), object: nil)
        }
    }
    
    var body: some View {
        HStack {
            TextField("New Tag", text: $newTag)
                .textInputAutocapitalization(.words)
                .foregroundColor(theme.foregroundColor())
                .onSubmit(addTag)
            
            if !newTag.isEmpty {
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.tintColor())
                }
            }
        }
    }
}
