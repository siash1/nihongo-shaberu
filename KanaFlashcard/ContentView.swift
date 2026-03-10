import SwiftUI

struct ContentView: View {
    @State private var viewModel = PracticeViewModel()

    var body: some View {
        NavigationStack {
            KanaSelectionView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
