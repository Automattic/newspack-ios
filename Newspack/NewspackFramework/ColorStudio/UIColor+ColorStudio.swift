import UIKit

/// HACK: Since ColorStudio is made up of enums, structs, and extensions, we will
/// use this empty class stub to reference the containing bundle. If Bundle(for:)
/// ever supports structs or enums we can switch to that approach instead.
private final class ColorStudioClass {}

extension UIColor {
    /// Get a UIColor from the Color Studio color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a ColorStudio
    /// - Returns: UIColor. Red in cases of error
    public class func withColorStudio(_ colorStudio: ColorStudio) -> UIColor {
        let assetName = colorStudio.assetName()
        let color = UIColor(named: assetName, in: Bundle(for: ColorStudioClass.self), compatibleWith: nil)

        guard let unwrappedColor = color else {
            return .red
        }

        return unwrappedColor
    }
    /// Get a UIColor from the Color Studio color palette, adjusted to a given shade
    /// - Parameter color: an instance of a ColorStudio
    /// - Parameter shade: a ColorStudioShade
    public class func withColorStudio(_ colorStudio: ColorStudio, shade: ColorStudioShade) -> UIColor {
        let newColor = ColorStudio(from: colorStudio, shade: shade)
        return withColorStudio(newColor)
    }
}


extension UIColor {
    // A way to create dynamic colors that's compatible with iOS 11 & 12
    public convenience init(light: UIColor, dark: UIColor) {
        if #available(iOS 13, *) {
            self.init { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            // in older versions of iOS, we assume light mode
            self.init(color: light)
        }
    }

    convenience init(color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIColor {
    public func color(for trait: UITraitCollection?) -> UIColor {
        if #available(iOS 13, *), let trait = trait {
            return resolvedColor(with: trait)
        }
        return self
    }
}
