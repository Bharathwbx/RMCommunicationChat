import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct FirebaseConstant {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timeStamp = "timeStamp"
    static let profileImageURL = "profileImageURL"
    static let email = "email"
    static let uid = "uid"
}

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
}

class ChatViewModel: ObservableObject {
    @Published var chatUser: ChatUser?
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages: [ChatMessage] = []
    
    var firestoreListener: ListenerRegistration?

    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        firestoreListener?.remove()
        chatMessages.removeAll()
        
        firestoreListener = FirebaseManager.shared.fireStore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstant.timeStamp)
            .addSnapshotListener { querySnapShot, error in
                if let error = error {
                    self.errorMessage = "Failed to retrieve message from Firestore. \(error)"
                    return
                }
                querySnapShot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            let cm = try change.document.data(as: ChatMessage.self)
                            self.chatMessages.append(cm)
                            print("Appending message at: \(Date())")
                        } catch {
                            print(error)
                        }
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.fireStore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstant.fromId: fromId, FirebaseConstant.toId: toId, FirebaseConstant.text: self.chatText, FirebaseConstant.timeStamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message in Firestore. \(error)"
                return
            }
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage()
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.fireStore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message in Firestore. \(error)"
                return
            }
            print("Recipient saved message as well")
        }
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let document = FirebaseManager.shared.fireStore.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(chatUser.uid)
                
        let data = [
            FirebaseConstant.timeStamp: Timestamp(),
            FirebaseConstant.text: chatText,
            FirebaseConstant.fromId: uid,
            FirebaseConstant.toId: chatUser.uid,
            FirebaseConstant.profileImageURL: chatUser.profileImageUrl,
            FirebaseConstant.email: chatUser.email
        ] as [String: Any]
                
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print(self.errorMessage)
                return
            }
        }
    }
    
    @Published var count = 0
}
