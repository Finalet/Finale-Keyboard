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
        static var setupFooter = NSLocalizedString("home_setup_footer", value: "Enable Finale Keyboard under system settings, then select it with 🌐 when typing.", comment: "")
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
    
    struct FavoriteEmojiScreen {
        static var title = HomeScreen.favoriteEmojiRow
        static var footer = NSLocalizedString("favorite_emoji_footer", value: "Pick emoji that are going to show up first in the emoji keyboard.", comment: "")
    }
    
    struct LanguagesScreen {
        static var title = NSLocalizedString("languages_title", value: "Languages", comment: "")
        static var english = NSLocalizedString("languages_english", value: "English", comment: "")
        static var russian = NSLocalizedString("languages_russian", value: "Russian", comment: "")
    }
    
    struct DictionaryScreen {
        static var title = HomeScreen.dictionaryRow
        static var learnWordsAutomatically = NSLocalizedString("dictionary_learn_words_automatically", value: "Learn words automatically", comment: "")
        static var learnWordsAutomaticallyIsOn = NSLocalizedString("dictionary_learn_words_automatically_toggle_is_on", value: "Turn off to stop Finale from automatically learning new words. You will still be able to add new words by swiping up.", comment: "")
        static var learnWordsAutomaticallyIsOff = NSLocalizedString("dictionary_learn_words_automatically_toggle_is_off", value: "Turn on to make Finale automatically learn new words. You will still be able to add new words by swiping up.", comment: "")
        static var footer = NSLocalizedString("dictionary_footer", value: "Finale can 'learn' new words. Just swipe up after typing an unrecognized word to add it to the dictionary.", comment: "")
    }
    
    struct PreferencesScreen {
        static var title = HomeScreen.preferencesRow
        static var autocorrectWords = NSLocalizedString("preferences_autocorrect_words", value: "Autocorrect Words", comment: "")
        static var autocorrectGrammar = NSLocalizedString("preferences_autocorrect_grammar", value: "Autocorrect Grammar", comment: "")
        static var autocapitalizeWords = NSLocalizedString("preferences_autocapitalize_words", value: "Autocapitalize Words", comment: "")
        static var typingHapticFeedback = NSLocalizedString("preferences_typing_haptic", value: "Typing Haptic Feedback", comment: "")
        static var gesturesHapticFeedback = NSLocalizedString("preferences_gestures_haptic", value: "Gestures Haptic Feedback", comment: "")
        
        struct Punctuation {
            static var pageTitle = NSLocalizedString("preferences_punctuation_page_title", value: "Quick Punctuation", comment: "")
            static var first = NSLocalizedString("preferences_punctuation_first", value: "First", comment: "")
            static var second = NSLocalizedString("preferences_punctuation_second", value: "Second", comment: "")
            static var third = NSLocalizedString("preferences_punctuation_third", value: "Third", comment: "")
            static var fourth = NSLocalizedString("preferences_punctuation_fourth", value: "Fourth", comment: "")
            static var fifth = NSLocalizedString("preferences_punctuation_fifth", value: "Fifth", comment: "")
            static var sixth = NSLocalizedString("preferences_punctuation_sixth", value: "Sixth", comment: "")
            static var seventh = NSLocalizedString("preferences_punctuation_seventh", value: "Seventh", comment: "")
            
            static var reset = NSLocalizedString("preferences_punctuation_reset", value: "Reset to Defaults", comment: "")
        }
        
        struct Advanced {
            static var pageTitle = NSLocalizedString("preferences_advanced_page_title", value: "Advanced", comment: "")
            
            static var sectionHeader = NSLocalizedString("preferences_advanced_section_header", value: "Auto-learn dictionary", comment: "")
            static var totalWords = NSLocalizedString("preferences_advanced_total_words", value: "Total words", comment: "")
            static var wordsOneUse = NSLocalizedString("preferences_advanced_words_one_use", value: "Words 1 use", comment: "")
            static var wordsTwoUse = NSLocalizedString("preferences_advanced_words_two_use", value: "Words 2 use", comment: "")
            static var cleanWordsOneUse = NSLocalizedString("preferences_advanced_clean_words_one_use", value: "Clean 1 use words", comment: "")
            static var cleanWordsTwoUse = NSLocalizedString("preferences_advanced_clean_words_two_use", value: "Clean 2 use words", comment: "")
        }
    }
    
    struct GesturesGuideScreen {
        static var inputFieldPlaceholder = HomeScreen.inputFieldPlaceholder
    }
    
}
