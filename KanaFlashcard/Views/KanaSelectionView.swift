import SwiftUI

struct KanaSelectionView: View {
    @Bindable var viewModel: PracticeViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                actionButtons

                kanaSection(title: "Hiragana", characters: KanaData.hiragana)
                kanaSection(title: "Katakana", characters: KanaData.katakana)

                startButton
            }
            .padding()
        }
        .navigationTitle("Select Characters")
        .navigationBarTitleDisplayMode(.large)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ActionButton(title: "All Hiragana", isActive: viewModel.allHiraganaSelected) {
                    viewModel.selectAllHiragana()
                }
                ActionButton(title: "All Katakana", isActive: viewModel.allKatakanaSelected) {
                    viewModel.selectAllKatakana()
                }
            }
            HStack(spacing: 10) {
                ActionButton(title: "Select All", isActive: false) {
                    viewModel.selectAll()
                }
                ActionButton(title: "Clear", isActive: false) {
                    viewModel.clearSelection()
                }
            }
        }
    }

    private func kanaSection(title: String, characters: [KanaCharacter]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(characters) { char in
                    KanaCell(
                        character: char,
                        isSelected: viewModel.isSelected(char)
                    ) {
                        viewModel.toggle(char)
                    }
                }
            }
        }
    }

    private var startButton: some View {
        NavigationLink {
            FlashcardView(viewModel: viewModel)
        } label: {
            Text("Start Practice (\(viewModel.selectionCount))")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canStartPractice ? .blue : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.canStartPractice)
        .padding(.top, 10)
    }
}

struct KanaCell: View {
    let character: KanaCharacter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(character.character)
                    .font(.title2)
                Text(character.romaji)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActionButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(isActive ? .blue : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
