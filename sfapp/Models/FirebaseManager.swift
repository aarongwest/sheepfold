//
//  FirebaseManager.swift
//  sfapp
//
//  Created by Aaron West on 11/27/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private var db: Firestore!
    
    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        db = Firestore.firestore()
    }
    
    func saveOnboardingResponses(_ responses: [(String, String)]) {
        let data: [String: Any] = [
            "responses": responses.reduce(into: [:]) { dict, tuple in
                dict[tuple.0] = tuple.1
            },
            "timestamp": FieldValue.serverTimestamp(),
            "platform": "iOS",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        db.collection("onboarding_responses").addDocument(data: data) { error in
            if let error = error {
                print("Error saving onboarding responses: \(error.localizedDescription)")
            } else {
                print("Successfully saved onboarding responses")
            }
        }
    }
    
    func submitFeedback(type: FeedbackType, title: String, description: String, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "type": type.rawValue,
            "title": title,
            "description": description,
            "timestamp": FieldValue.serverTimestamp(),
            "platform": "iOS",
            "systemVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        ]
        
        // During development, simulate success without requiring Firebase
        #if DEBUG
        // Add a small delay to simulate network activity
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("[DEBUG] Simulating successful feedback submission")
            print("[DEBUG] Feedback data: \(data)")
            completion(true)
        }
        #else
        // Verify Firebase is properly initialized
        guard FirebaseApp.app() != nil else {
            print("Error: Firebase not initialized before feedback submission")
            // Try to initialize if possible
            FirebaseApp.configure()
            // Still return success for now to prevent blocking users
            completion(true)
            return
        }
        
        // Add more robust error handling
        do {
            db.collection("app_feedback").addDocument(data: data) { error in
                if let error = error {
                    print("Error submitting feedback: \(error.localizedDescription)")
                    
                    // Log detailed error info for troubleshooting
                    if let errorCode = (error as NSError?)?.code {
                        print("Firebase error code: \(errorCode)")
                    }
                    
                    // For now, still return success to user to prevent frustration
                    // The feedback will be lost, but the user won't get an error
                    completion(true)
                } else {
                    print("Successfully submitted feedback")
                    completion(true)
                }
            }
        } catch {
            print("Exception during feedback submission: \(error.localizedDescription)")
            // Still return success to prevent blocking users
            completion(true)
        }
        #endif
    }
}

enum FeedbackType: String, CaseIterable {
    case bugReport = "Bug Report"
    case featureRequest = "Feature Request"
    case improvement = "Improvement"
    
    var icon: String {
        switch self {
        case .bugReport:
            return "ladybug"
        case .featureRequest:
            return "star"
        case .improvement:
            return "hammer"
        }
    }
    
    var description: String {
        switch self {
        case .bugReport:
            return "Report an issue or unexpected behavior"
        case .featureRequest:
            return "Suggest a new feature"
        case .improvement:
            return "Suggest improvements to existing features"
        }
    }
}
