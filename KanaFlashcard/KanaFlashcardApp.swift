//
//  KanaFlashcardApp.swift
//  KanaFlashcard
//
//  Created by Ashish Bisht on 06/03/26.
//

import SwiftUI
import UIKit

@main
struct KanaFlashcardApp: App {
    /// One shared kanji progress model for every window.
    @State private var kanjiViewModel = KanjiViewModel()

    init() {
        // .fontDesign(.rounded) does not reach UIKit navigation bars, so give their titles the
        // rounded face here. Only the text attributes are set: assigning a whole appearance would
        // replace the system's glass bar and its scroll-edge effect.
        let navigationBar = UINavigationBar.appearance()
        if let largeTitle = Self.roundedFont(.largeTitle, weight: .bold) {
            navigationBar.largeTitleTextAttributes = [.font: largeTitle]
        }
        // The inline bar is a fixed height, so its title stops growing at a readable size.
        if let title = Self.roundedFont(.headline, weight: .semibold, maximumPointSize: 28) {
            navigationBar.titleTextAttributes = [.font: title]
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(kanjiViewModel: kanjiViewModel)
        }
    }

    /// The system font for a text style in its rounded design, scaled with Dynamic Type once.
    /// It starts from the default-size font: starting from the user's size and scaling again would
    /// scale twice and make titles oversized at large text sizes.
    private static func roundedFont(_ style: UIFont.TextStyle, weight: UIFont.Weight, maximumPointSize: CGFloat? = nil) -> UIFont? {
        let defaultSize = UITraitCollection(preferredContentSizeCategory: .large)
        let base = UIFont.preferredFont(forTextStyle: style, compatibleWith: defaultSize)
        let weighted = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
        guard let descriptor = weighted.fontDescriptor.withDesign(.rounded) else { return nil }
        let rounded = UIFont(descriptor: descriptor, size: base.pointSize)
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maximumPointSize {
            return metrics.scaledFont(for: rounded, maximumPointSize: maximumPointSize)
        }
        return metrics.scaledFont(for: rounded)
    }
}
