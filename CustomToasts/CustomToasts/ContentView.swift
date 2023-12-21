import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Press") {
                Toast.shared.present(title: "Hello World", symbol: "globe", isUserInteractionEnable: true)
            }
        }
        .padding()
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
