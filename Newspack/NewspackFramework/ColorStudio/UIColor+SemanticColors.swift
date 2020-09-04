import UIKit

// MARK: - Base colors.
extension UIColor {
    /// Accent. accent-50 (< iOS 13 and Light Mode) and accent-30 (Dark Mode)
    ///
    public static var accent: UIColor {
        return UIColor(light: .withColorStudio(.accent, shade: .shade50),
                       dark: .withColorStudio(.accent, shade: .shade30))
    }

    /// Accent Dark. accent-70 (< iOS 13 and Light Mode) and accent-50 (Dark Mode)
    ///
    public static var accentDark: UIColor {
        return UIColor(light: .withColorStudio(.accent, shade: .shade70),
                       dark: .withColorStudio(.accent, shade: .shade50))
    }

    /// Brand. brand (all versions of iOS, Light and Dark Mode)
    ///
    public static var brand = UIColor.withColorStudio(.brand)

    /// Error. error-50 (< iOS 13 and Light Mode) and error-30 (Dark Mode)
    ///
    public static var error: UIColor {
        return UIColor(light: .withColorStudio(.error, shade: .shade50),
                        dark: withColorStudio(.error, shade: .shade30))
    }

    /// Error Dark. error-70 (< iOS 13 and Light Mode) and error-50 (Dark Mode)
    ///
    public static var errorDark: UIColor {
        return UIColor(light: .withColorStudio(.error, shade: .shade70),
                       dark: .withColorStudio(.error, shade: .shade50))
    }

    /// Primary. primary-60 (< iOS 13 and Light Mode) and primary-30 (Dark Mode)
    ///
    public static var primary: UIColor {
        return UIColor(light: .withColorStudio(.primary),
                       dark: .withColorStudio(.primary, shade: .shade30))
    }

    /// Primary Dark. primary-80 (< iOS 13 and Light Mode) and primary-50 (Dark Mode)
    ///
    public static var primaryDark: UIColor {
        return UIColor(light: .withColorStudio(.primary, shade: .shade80),
                       dark: .withColorStudio(.primary, shade: .shade50))
    }

    /// Success. success-50 (< iOS 13 and Light Mode) and success-30 (Dark Mode)
    ///
    public static var success: UIColor {
        return UIColor(light: .withColorStudio(.success, shade: .shade50),
                       dark: .withColorStudio(.success, shade: .shade30))
    }

    /// Warning. warning-50 (< iOS 13 and Light Mode) and warning-30 (Dark Mode)
    ///
    public static var warning: UIColor {
        return UIColor(light: .withColorStudio(.warning, shade: .shade50),
                       dark: .withColorStudio(.warning, shade: .shade30))
    }
}


// MARK: - Text Colors.
extension UIColor {
    /// Text link. accent
    ///
    public static var textLink: UIColor {
        return .accent
    }

    /// Text. Gray-80 (< iOS 13) and `UIColor.label` (> iOS 13)
    ///
    public static var text: UIColor {
        return .neutral(.shade80)
    }

    /// Text Subtle. Gray-50 (< iOS 13) and `UIColor.secondaryLabel` (> iOS 13)
    ///
    public static var textSubtle: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }

        return .neutral(.shade50)
    }

    /// Text Tertiary. Gray-20 (< iOS 13) and `UIColor.tertiaryLabel` (> iOS 13)
    ///
    public static var textTertiary: UIColor {
        if #available(iOS 13, *) {
            return .tertiaryLabel
        }

        return .gray(.shade20)
    }

    /// Text Quaternary. Gray-10 (< iOS 13) and `UIColor.quaternaryLabel` (> iOS 13)
    ///
    public static var textQuaternary: UIColor {
        if #available(iOS 13, *) {
            return .quaternaryLabel
        }

        return .gray(.shade10)
    }

    /// Text Inverted. White(< iOS 13 and Light Mode) and Gray-90 (Dark Mode)
    ///
    public static var textInverted: UIColor {
        return UIColor(light: .white,
                       dark: .withColorStudio(.gray, shade: .shade90))
    }

    /// Text Placeholder. Gray-30 (< iOS 13) and `UIColor.placeholderText` (> iOS 13)
    ///
    public static var textPlaceholder: UIColor {
        if #available(iOS 13, *) {
            return .placeholderText
        }

        return .gray(.shade30)
    }

    /// Cancel Action Text Color.
    ///
    public static var modalCancelAction: UIColor {
        return UIColor(light: .accent,
                       dark: .label)
    }

    /// Text. newspackBlue-60 (< iOS 13 and Light Mode) and newspackBlue-30 (Dark Mode)
    ///
    public static var textBrand: UIColor {
        return UIColor(light: .withColorStudio(.brand),
                       dark: .withColorStudio(.brand))
    }
}


// MARK: - Image Colors.
extension UIColor {
    /// Placeholder image tint color.
    ///
    public static var placeholderImage: UIColor {
        return .gray(.shade20)
    }
}

// MARK: - UI elements.
extension UIColor {
    /// Basic Background. White (< iOS 13) and `UIColor.systemBackground` (> iOS 13)
    ///
    public static var basicBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }

        return .white
    }

    /// Selection color.
    ///
    public static var selection: UIColor {
        return UIColor(light: .newspackBlue(.shade20),
                       dark: .newspackBlue(.shade80))
    }

    /// Cell default background color
    ///
    public static var cellBackground: UIColor {
        return basicBackground
    }

    /// Cell selected background color
    ///
    public static var cellBackgroundSelected: UIColor {
        return selection
    }

    /// App Navigation Bar. brand (< iOS 13 and Light Mode) and `UIColor.systemThickMaterial` (Dark Mode)
    ///
    public static var appBar: UIColor {
        return .systemBackground
    }

    /// App Tab Bar.
    ///
    public static var appTabBar: UIColor {
        return UIColor(light: .basicBackground,
        dark: .secondarySystemGroupedBackground)
    }

    /// Tab Unselected. Gray-20 (< iOS 13 and Light Mode) and Gray-60 (Dark Mode)
    ///
    public static var tabUnselected: UIColor {
        return UIColor(light: .withColorStudio(.gray, shade: .shade20),
                       dark: .withColorStudio(.gray, shade: .shade60))
    }

    /// Divider. Gray-10 (< iOS 13) and `UIColor.separator` (> iOS 13)
    ///
    public static var divider: UIColor {
        if #available(iOS 13, *) {
            return .separator
        }

        return .withColorStudio(.gray, shade: .shade10)
    }

    /// Primary Button Background. Resolves to `accent`
    ///
    public static var primaryButtonBackground = accent

    /// Primary Button Title.
    ///
    public static var primaryButtonTitle: UIColor {
        return .white
    }

    /// Primary Button Border.
    ///
    public static var primaryButtonBorder = UIColor.clear

    /// Primary Button Highlighted Background.
    ///
    public static var primaryButtonDownBackground = accentDark

    /// Primary Button Highlighted Border.
    ///
    public static var primaryButtonDownBorder = accentDark

    /// Secondary Button Background.
    ///
    public static var secondaryButtonBackground: UIColor {
        return UIColor(light: .white,
                       dark: .systemGray5)
    }

    /// Secondary Button Title.
    ///
    public static var secondaryButtonTitle: UIColor {
        return .label
    }

    /// Secondary Button Border.
    ///
    public static var secondaryButtonBorder: UIColor {
        return .systemGray3
    }

    /// Secondary Button Highlighted Background.
    ///
    public static var secondaryButtonDownBackground: UIColor {
        return .systemGray3
    }

    /// Secondary Button Highlighted Border.
    ///
    public static var secondaryButtonDownBorder: UIColor {
        return .systemGray3
    }

    /// Button Disabled Background.
    ///
    public static var buttonDisabledBackground: UIColor {
        return .clear
    }

    /// Button Disabled Title.
    ///
    public static var buttonDisabledTitle: UIColor {
        return .quaternaryLabel
    }

    /// Button Disabled Border.
    ///
    public static var buttonDisabledBorder: UIColor {
        return .systemGray3
    }

    /// Filter Bar Selected. `primary` (< iOS 13 and Light Mode) and `UIColor.label` (Dark Mode)
    ///
    public static var filterBarSelected: UIColor {
        if #available(iOS 13, *) {
            return UIColor(light: .primary,
                           dark: .label)
        }


        return .primary
    }

    /// Filter Bar Background. `white` (< iOS 13 and Light Mode) and Gray-90 (Dark Mode)
    ///
    public static var filterBarBackground: UIColor {
        return UIColor(light: .white,
                       dark: .withColorStudio(.gray, shade: .shade90))
    }

}

// MARK: - Borders.
extension UIColor {
    /// Default border color.
    ///
    public static var border: UIColor {
        return .systemGray4
    }
}


// MARK: - Table Views.
extension UIColor {
    /// List Icon. Gray-20 (< iOS 13) and `UIColor.secondaryLabel` (> iOS 13)
    ///
    public static var listIcon: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }

        return .withColorStudio(.gray, shade: .shade20)
    }

    /// List Small Icon. Gray-20 (< iOS 13) and `UIColor.systemGray` (> iOS 13)
    ///
    public static var listSmallIcon: UIColor {
        if #available(iOS 13, *) {
            return .systemGray
        }

        return .withColorStudio(.gray, shade: .shade20)
    }

    /// List BackGround. Gray-0 (< iOS 13) and `UIColor.systemGroupedBackground` (> iOS 13)
    ///
    public static var listBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemGroupedBackground
        }

        return .withColorStudio(.gray, shade: .shade0)
    }

    /// List ForeGround. `UIColor.white` (< iOS 13) and `UIColor.secondarySystemGroupedBackground` (> iOS 13)
    ///
    public static var listForeground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemGroupedBackground
        }

        return .white
    }

    /// Section Header Text Color
    ///
    public static var sectionLableTextColor: UIColor {
        let light = UIColor(red: 109.0/255.0, green: 109.0/255.0, blue: 114.0/255.0, alpha: 1.0)
        let dark = UIColor(red: 142.0/255.0, green: 142.0/255.0, blue: 147.0/255.0, alpha: 1.0)
        return UIColor(light: light, dark: dark)
    }
}


// MARK: - Login.
extension UIColor {
    class var alertHeaderImageBackgroundColor: UIColor {
        return UIColor(light: .systemGray6,
                       dark: .systemGray5)
    }
}


// MARK: - Grays
extension UIColor {
    /// ColorStudio gray palette
    /// - Parameter shade: a ColorStudioShade of the desired shade of gray
    class func gray(_ shade: ColorStudioShade) -> UIColor {
        return .withColorStudio(.gray, shade: shade)
    }

    /// ColorStudio neutral colors, which invert in dark mode
    /// - Parameter shade: a ColorStudioShade of the desired neutral shade
    public static var neutral: UIColor {
        return neutral(.shade50)
    }

    public class func neutral(_ shade: ColorStudioShade) -> UIColor {
        switch shade {
        case .shade0:
            return UIColor(light: .withColorStudio(.gray, shade: .shade0), dark: .withColorStudio(.gray, shade: .shade100))
            case .shade5:
                return UIColor(light: .withColorStudio(.gray, shade: .shade5), dark: .withColorStudio(.gray, shade: .shade90))
            case .shade10:
                return UIColor(light: .withColorStudio(.gray, shade: .shade10), dark: .withColorStudio(.gray, shade: .shade80))
            case .shade20:
                return UIColor(light: .withColorStudio(.gray, shade: .shade20), dark: .withColorStudio(.gray, shade: .shade70))
            case .shade30:
                return UIColor(light: .withColorStudio(.gray, shade: .shade30), dark: .withColorStudio(.gray, shade: .shade60))
            case .shade40:
                return UIColor(light: .withColorStudio(.gray, shade: .shade40), dark: .withColorStudio(.gray, shade: .shade50))
            case .shade50:
                return UIColor(light: .withColorStudio(.gray, shade: .shade50), dark: .withColorStudio(.gray, shade: .shade40))
            case .shade60:
                return UIColor(light: .withColorStudio(.gray, shade: .shade60), dark: .withColorStudio(.gray, shade: .shade30))
            case .shade70:
                return UIColor(light: .withColorStudio(.gray, shade: .shade70), dark: .withColorStudio(.gray, shade: .shade20))
            case .shade80:
                return UIColor(light: .withColorStudio(.gray, shade: .shade80), dark: .withColorStudio(.gray, shade: .shade10))
            case .shade90:
                return UIColor(light: .withColorStudio(.gray, shade: .shade90), dark: .withColorStudio(.gray, shade: .shade5))
            case .shade100:
                return UIColor(light: .withColorStudio(.gray, shade: .shade100), dark: .withColorStudio(.gray, shade: .shade0))
        }
    }
}

// MARK: - Newspack Blues
extension UIColor {
    public class func newspackBlue(_ shade: ColorStudioShade) -> UIColor {
        switch shade {
        case .shade0:
            return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade0), dark: .withColorStudio(.newspackBlue, shade: .shade100))
            case .shade5:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade5), dark: .withColorStudio(.newspackBlue, shade: .shade90))
            case .shade10:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade10), dark: .withColorStudio(.newspackBlue, shade: .shade80))
            case .shade20:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade20), dark: .withColorStudio(.newspackBlue, shade: .shade70))
            case .shade30:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade30), dark: .withColorStudio(.newspackBlue, shade: .shade60))
            case .shade40:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade40), dark: .withColorStudio(.newspackBlue, shade: .shade50))
            case .shade50:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade50), dark: .withColorStudio(.newspackBlue, shade: .shade40))
            case .shade60:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade60), dark: .withColorStudio(.newspackBlue, shade: .shade30))
            case .shade70:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade70), dark: .withColorStudio(.newspackBlue, shade: .shade20))
            case .shade80:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade80), dark: .withColorStudio(.newspackBlue, shade: .shade10))
            case .shade90:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade90), dark: .withColorStudio(.newspackBlue, shade: .shade5))
            case .shade100:
                return UIColor(light: .withColorStudio(.newspackBlue, shade: .shade100), dark: .withColorStudio(.newspackBlue, shade: .shade0))
        }
    }
}
