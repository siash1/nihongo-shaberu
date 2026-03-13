import SwiftUI

struct FlashcardView: View {
    @Bindable var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            if viewModel.isPracticeComplete {
                completionView
            } else if let card = viewModel.currentCard {
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

            if !viewModel.isPracticeComplete {
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
                        HStack(spacing: 14) {
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    viewModel.markWrong()
                                }
                            } label: {
                                Text("Wrong")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    viewModel.markCorrect()
                                }
                            } label: {
                                Text("Correct")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(viewModel.remainingCount) left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            viewModel.startPractice()
        }
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Practice Complete!")
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.scoreText + " correct on first try")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
}
