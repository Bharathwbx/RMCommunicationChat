import Firebase
import FirebaseStorage

class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    let fireStore: Firestore
    
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        auth = Auth.auth()
        storage = Storage.storage()
        fireStore = Firestore.firestore()
        super.init()
    }
}
