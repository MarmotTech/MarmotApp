import SwiftUI

extension UIApplication {
    static var keyWindow: UIWindow? {
        UIApplication.shared
            .connectedScenes.lazy
            .compactMap { $0.activationState == .foregroundActive ? ($0 as? UIWindowScene) : nil }
            .first(where: { $0.keyWindow != nil })?
            .keyWindow
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.keyWindow?.safeAreaInsets.swiftUiInsets ?? EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
