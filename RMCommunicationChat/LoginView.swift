import SwiftUI
import Firebase

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var shouldShowImagePicker = false
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            if let image = self.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    .cornerRadius(128)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .padding()
                            }
                        }.overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(.black, lineWidth: 3))
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress )
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Login" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(.blue)
                    }
                    Text(loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Login" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                            .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            didCompleteLoginProcess()
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if image == nil {
            loginStatusMessage = "You must select an avatar image"
            return
        }
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            loginStatusMessage = "Successfully created a user: \(result?.user.uid ?? "")"
            persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metaData, err in
            if let err = err {
                print(err)
                self.loginStatusMessage = "Failed to push image to storage \(err)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    loginStatusMessage = "Failed to retrieve download url \(err)"
                }
                loginStatusMessage = "Successfully stored image with url : \(url?.absoluteString ?? "")"
                guard let url = url else { return }
                storeUserInformation(imageProfileURL: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileURL: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userDetails = ["email": self.email, "uid": uid,  "profileImageURL": imageProfileURL.absoluteString]
        
        FirebaseManager.shared.fireStore.collection("users").document(uid).setData(userDetails) { err in
            if let err = err {
                print(err)
                loginStatusMessage = "\(err)"
            }
            print("Successfully saved in firestore!")
            didCompleteLoginProcess()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
        })
    }
}
