//
//  Localization.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 7/21/22.
//

import Foundation

/// Localization namespace
struct Localization {
    
    struct HomeScreen {
        static var inputFieldTitle = NSLocalizedString("home_input_field_title", value: "Try it out", comment: "Short invitation to try the keyboard")
        static var inputFieldPlaceholder = NSLocalizedString("home_input_field_placeholder", value: "Try typing here", comment: "Placeholder for the input field where users can try the keyboard")
        
        static var preferencesTitle = NSLocalizedString("home_preferences_title", value: "Preferences", comment: "")
        static var favoriteEmojiRow = NSLocalizedString("home_favorite_emoji_row", value: "Favorite Emoji", comment: "")
        static var languagesRow = NSLocalizedString("home_languages_row", value: "Languages", comment: "")
        static var dictionaryRow = NSLocalizedString("home_dictionary_row", value: "Dictionary", comment: "")
        static var preferencesRow = NSLocalizedString("home_preferences_row", value: "Preferences", comment: "")
        
        static var setupTitle = NSLocalizedString("home_setup_title", value: "Setup", comment: "")
        static var setupFooter = NSLocalizedString("home_setup_footer", value: "Enable Finale keyboard under system settings, then select it with 🌐 when typing.", comment: "")
        static var keyboardDisabledAlert = NSLocalizedString("home_keyboard_disabled_row", value: "Keyboard is disabled", comment: "")
        static var keyboardEnabledAlert = NSLocalizedString("home_keyboard_enabled_row", value: "Keyboard is enabled", comment: "")
        static var keyboardFullAccessDisabled = NSLocalizedString("home_keyboard_full_access_disabled_row", value: "Full Access is disabled", comment: "")
        static var keyboardFullAccessEnabled = NSLocalizedString("home_keyboard_full_access_enabled_row", value: "Full Access is enabled", comment: "")
        static var systemSettingsRow = NSLocalizedString("home_system_settings_row", value: "System Settings", comment: "")
        
        static var helpTitle = NSLocalizedString("home_help_title", value: "Help", comment: "")
        static var gesturesGuideRow = NSLocalizedString("home_gestures_guide_row", value: "Gestures Guide", comment: "")
        static var contactDeveloperRow = NSLocalizedString("home_contact_developer_row", value: "Contact Developer", comment: "")
        static var moreRow = NSLocalizedString("home_more_row", value: "More", comment: "")
    }
}
