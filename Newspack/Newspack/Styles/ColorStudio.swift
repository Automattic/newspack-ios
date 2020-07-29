/// Generates the names of the named colors in the ColorPalette.xcasset
enum ColorStudioName: String, CustomStringConvertible {
    // MARK: - Base colors
    case blue
    case celadon
    case gray
    case green
    case orange
    case pink
    case purple
    case red
    case yellow
    case newspackBlue

    var description: String {
        // can't use .capitalized because it lowercases the B in "newspackBlue"
        return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

/// Value of a ColorStudio color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
enum ColorStudioShade: Int, CustomStringConvertible {
    case shade0 = 0
    case shade5 = 5
    case shade10 = 10
    case shade20 = 20
    case shade30 = 30
    case shade40 = 40
    case shade50 = 50
    case shade60 = 60
    case shade70 = 70
    case shade80 = 80
    case shade90 = 90
    case shade100 = 100

    var description: String {
        return "\(rawValue)"
    }
}


/// Conformance to CaseIterable will be useful for testing.
extension ColorStudioShade: CaseIterable { }


/// A specific color and shade from Color Studio
struct ColorStudio {
    let name: ColorStudioName
    let shade: ColorStudioShade

    init(name: ColorStudioName, shade: ColorStudioShade = .shade50) {
        self.name = name
        self.shade = shade
    }

    init(from identifier: ColorStudio, shade: ColorStudioShade) {
        self.name = identifier.name
        self.shade = shade
    }

    // MARK: - Semantic colors
    static let newspackBlue = ColorStudio(name: .newspackBlue)
    static let brand = ColorStudio(name: .newspackBlue)
    static let accent = ColorStudio(name: .newspackBlue)
    static let divider = ColorStudio(name: .gray, shade: .shade10)
    static let error = ColorStudio(name: .red)
    static let gray = ColorStudio(name: .gray)
    static let primary = ColorStudio(name: .blue)
    static let success = ColorStudio(name: .green)
    static let text = ColorStudio(name: .gray, shade: .shade80)
    static let textSubtle = ColorStudio(name: .gray, shade: .shade50)
    static let warning = ColorStudio(name: .yellow)

    /// The full name of the color, with required shade value
    func assetName() -> String {
        return "\(name)\(shade)"
    }
}
