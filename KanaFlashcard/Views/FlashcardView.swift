import SwiftUI

struct FlashcardView: View {
    @Bindable var viewModel: PracticeViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            if let card = viewModel.currentCard {
                Text(card.type.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(2)

                Text(card.character)
                    .font(.system(size: 120))
                    .padding()

                if viewModel.isAnswerRevealed {
                    Text(card.romaji)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer()

            VStack(spacing: 14) {
                if !viewModel.isAnswerRevealed {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.revealAnswer()
                        }
                    } label: {
                        Text("Reveal Answer")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.showNextCard()
                        }
                    } label: {
                        Text("Next Card")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startPractice()
        }
    }
}
