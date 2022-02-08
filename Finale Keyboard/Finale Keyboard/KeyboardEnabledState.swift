#if os(iOS) || os(tvOS)
import Foundation
import Combine
import UIKit

/**
 This state class implements `KeyboardEnabledStateInspector`
 by keeping a published `isKeyboardEnabled` in sync with the
 state of the associated keyboard.
 
 This class will call `refresh` whenever the app or keyboard
 extension becomes active.
 */
public class KeyboardEnabledState: KeyboardEnabledStateInspector, ObservableObject {
    
    /**
     Create an instance of this observable state class.
     
     Make sure to use the `bundleId` of the keyboard and not
     the main application.
     
     - Parameters:
       - bundleId: The bundle ID of the keyboard extension.
       - notificationCenter: The notification center to use to observe changes.
     */
    public init(
        bundleId: String,
        notificationCenter: NotificationCenter = .default) {
        self.bundleId = bundleId
        self.notificationCenter = notificationCenter
        activePublisher.sink(receiveValue: { [weak self] _ in
            self?.refresh()
        }).store(in: &cancellables)
        textPublisher.delay(for: 0.5, scheduler: RunLoop.main).sink(receiveValue: { [weak self] _ in
            self?.refresh()
        }).store(in: &cancellables)
        refresh()
    }
    
    public let bundleId: String
    
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter: NotificationCenter
    
    /**
     Whether or not the keyboard extension with the specific
     ``bundleId`` is currently being used in a text field.
     */
    @Published public var isKeyboardCurrentlyActive: Bool = false
    
    /**
     Whether or not the keyboard extension with the specific
     ``bundleId`` has been enabled in System Settings.
     */
    @Published public var isKeyboardEnabled: Bool = false
    
    /**
     Refresh state for the currently used keyboard extension.
     */
    public func refresh() {
        isKeyboardCurrentlyActive = isKeyboardCurrentlyActive(withBundleId: bundleId)
        isKeyboardEnabled = isKeyboardEnabled(withBundleId: bundleId)
    }
}

private extension KeyboardEnabledState {
    
    var activePublisher: NotificationCenter.Publisher {
        publisher(for: UIApplication.didBecomeActiveNotification)
    }
    
    var textPublisher: NotificationCenter.Publisher {
        publisher(for: UITextInputMode.currentInputModeDidChangeNotification)
    }
    
    func publisher(for notification: Notification.Name) -> NotificationCenter.Publisher {
        notificationCenter.publisher(for: notification)
    }
}
#endif

#if os(iOS) || os(tvOS)
import Foundation
import UIKit

/**
 This protocol can be implemented by any class or struct and
 provides its implementations with state-specific extensions.
 
 However, the easiest way to observe the enabled state is to
 just create an `KeyboardEnabledState` instance.
 */
public protocol KeyboardEnabledStateInspector {}

public extension KeyboardEnabledStateInspector {
    
    /**
     Check whether or not the app has been given full access
     in System Settings.
     */
    var isFullAccessEnabled: Bool {
        FullAccessInspector().hasFullAccess
    }
    
    /**
     Whether or not the keyboard extension with the provided
     `bundleId` is currently being used in a text field.
     
     - Parameter withBundleId: The bundle id of the keyboard extension.
     */
    func isKeyboardCurrentlyActive(
        withBundleId bundleId: String) -> Bool {
        let modes = UITextInputMode.activeInputModes
        let displayedModes = modes.filter { $0.value(forKey: "isDisplayed") as? Int == 1 }
        let id = displayedModes.map { $0.value(forKey: "identifier") as? String }
        return bundleId == id.first
    }
    
    /**
     Whether or not the keyboard extension with the provided
     `bundleId` has been enabled in System Settings.
     
     - Parameter withBundleId: The bundle id of the keyboard extension.
     - Parameter defaults: The user defaults instance to check.
     */
    func isKeyboardEnabled(
        withBundleId bundleId: String,
        defaults: UserDefaults = .standard) -> Bool {
        let key = "AppleKeyboards"
        guard let settings = defaults.object(forKey: key) as? [String] else { return false }
        return settings.contains(bundleId)
    }
}

private class FullAccessInspector: UIInputViewController {}
#endif
