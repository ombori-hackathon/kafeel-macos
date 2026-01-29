import SwiftUI
import LocalAuthentication

struct SecureActionButton: View {
    let title: String
    let systemImage: String?
    let role: ButtonRole?
    let reason: String
    let action: () -> Void

    @State private var showError = false
    @State private var errorMessage = ""

    init(
        _ title: String,
        systemImage: String? = nil,
        role: ButtonRole? = nil,
        reason: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.reason = reason
        self.action = action
    }

    var body: some View {
        Button(role: role) {
            Task {
                await authenticateAndPerform()
            }
        } label: {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .alert("Authentication Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func authenticateAndPerform() async {
        let context = LAContext()
        var error: NSError?

        // Check if authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Authentication not available"
            showError = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                action()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
