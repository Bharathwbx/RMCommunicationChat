struct ChatUser: Identifiable {
    var id: String { uid }
    let uid, profileImageUrl, email: String
    
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.profileImageUrl = data["profileImageURL"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
    }
    
    var name: String {
        email.replacingOccurrences(of: "@cnb.com", with: "").capitalized
    }
}


