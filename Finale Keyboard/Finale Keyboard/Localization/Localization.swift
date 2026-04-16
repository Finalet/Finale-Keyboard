//
//  Localization.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 7/21/22.
//

import Foundation

/// Localization namespace
struct Localization {
    
    struct HomeScreen {
        static var inputFieldTitle = NSLocalizedString("home_input_field_title", value: "Try it out", comment: "Short invitation to try the keyboard")
        static var inputFieldPlaceholder = NSLocalizedString("home_input_field_placeholder", value: "Try typing here", comment: "Placeholder for the input field where users can try the keyboard")
        
        static var preferencesTitle = NSLocalizedString("home_preferences_title", value: "Preferences", comment: "")
        static var favoriteEmojiRow = NSLocalizedString("home_favorite_emoji_row", value: "Favorite Emoji", comment: "")
        static var shortcutsRow = NSLocalizedString("home_shortcuts_row", value: "Shortcuts", comment: "")
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
        static var developerTitle = NSLocalizedString("home_developer_title", value: "Developer", comment: "")
        static var profileRow = NSLocalizedString("home_profile_row", value: "Profile", comment: "")
        static var messageMeRow = NSLocalizedString("home_message_me_row", value: "Message me", comment: "")
        static var contactDeveloperRow = NSLocalizedString("home_contact_developer_row", value: "Contact Developer", comment: "")
        static var moreRow = NSLocalizedString("home_more_row", value: "More", comment: "")
    }
    
    struct Actions {
        static var enable = NSLocalizedString("actions_enable", value: "Enable", comment: "")
        static var load = NSLocalizedString("actions_load", value: "Load", comment: "")
        static var delete = NSLocalizedString("actions_delete", value: "Delete", comment: "")
        static var clear = NSLocalizedString("actions_clear", value: "Clear", comment: "")
        static var export = NSLocalizedString("actions_export", value: "Export", comment: "")
        static var Import = NSLocalizedString("actions_import", value: "Import", comment: "")
        static var done = NSLocalizedString("actions_done", value: "Done", comment: "")
        static var continueButton = NSLocalizedString("actions_continue", value: "Continue", comment: "")
    }
    
    struct Misc {
        static var Default = NSLocalizedString("misc_default", value: "Default", comment: "")
        static var loading = NSLocalizedString("misc_loading", value: "Loading", comment: "")
        static var deleting = NSLocalizedString("misc_deleting", value: "Deleting", comment: "")
    }
    
    struct FavoriteEmojiScreen {
        static var title = HomeScreen.favoriteEmojiRow
        static var footer = NSLocalizedString("favorite_emoji_footer", value: "Pick emoji that are going to show up first in the emoji keyboard.", comment: "")
    }
    
    struct Shortcuts {
        static var title = HomeScreen.shortcutsRow
        static var headerTitle = NSLocalizedString("shortcuts_header_title", value: "Swipe down on a key to trigger its shortcut", comment: "")
        static var headerDescription = NSLocalizedString("shortcuts_header_description", value: "Shortcuts override the regular swipe-down gesture, so leave some empty keys convenience.", comment: "")
        
        static var symbols = NSLocalizedString("shortcuts_symbols", value: "Symbols", comment: "")
        static var extraSymbols = NSLocalizedString("shortcuts_extra_symbols", value: "Extra Symbols", comment: "")
        
        static var restoreDefaults = NSLocalizedString("shortcuts_restore_defaults", value: "Restore Defaults", comment: "")
        static var populateEmoji = NSLocalizedString("shortcuts_populate_emoji", value: "Populate Emoji", comment: "")
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
        static var clearDictionaryConfirmation = NSLocalizedString("dictionary_clear_dictionary_confirmation", value: "Are your sure you want to clear the dictionary?", comment: "")
        static var footer = NSLocalizedString("dictionary_footer", value: "Finale can 'learn' new words. Just swipe up after typing an unrecognized word to add it to the dictionary.", comment: "")
    }
    
    struct PreferencesScreen {
        static var title = HomeScreen.preferencesRow
        static var autocorrectWords = NSLocalizedString("preferences_autocorrect_words", value: "Autocorrect Words", comment: "")
        static var autocorrectGrammar = NSLocalizedString("preferences_autocorrect_grammar", value: "Autocorrect Grammar", comment: "")
        static var autocapitalizeWords = NSLocalizedString("preferences_autocapitalize_words", value: "Autocapitalize Words", comment: "")
        static var typingHapticFeedback = NSLocalizedString("preferences_typing_haptic", value: "Typing Haptic Feedback", comment: "")
        static var gesturesHapticFeedback = NSLocalizedString("preferences_gestures_haptic", value: "Gestures Haptic Feedback", comment: "")
        static var spacebar = NSLocalizedString("preferences_spacebar", value: "Spacebar", comment: "")
        static var spacebarAutocorrect = NSLocalizedString("preferences_spacebar_autocorrect", value: "Spacebar Autocorrect", comment: "")
        
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
        
        struct DynamicTouchZones {
            static var pageTitle = NSLocalizedString("preferences_dynamic_touch_zones_page_title", value: "Dynamic Touch Zones", comment: "")
            
            static var explanation = NSLocalizedString("preferences_dynamic_touch_zones_explanation", value: "When enabled, Finale Keyboard will try to predict what key you will tap next and slightly increase its tap zone.", comment: "")
            static var highlightKeys = NSLocalizedString("preferences_dynamic_touch_zones_highlight_keys", value: "Highlight keys", comment: "")
            static var dictionaryRequired = NSLocalizedString("preferences_dynamic_touch_zones_dictionary_required", value: "Dictionary is required for dynamic touch zones to work.", comment: "")
            static var showTouchZones = NSLocalizedString("preferences_dynamic_touch_zones_show_touch_zones", value: "Show touch zones", comment: "")
            static var maximumKeyScale = NSLocalizedString("preferences_dynamic_touch_zones_max_key_scale", value: "Maximum key scale", comment: "")
            static var scaleMultiplier = NSLocalizedString("preferences_dynamic_touch_zones_scale_multiplier", value: "Scale multiplier", comment: "")
            static var loadingDurationWarning = NSLocalizedString("preferences_dynamic_touch_zones_loading_duration_warning", value: "%@ can take up to a minute. Do not leave this page until it is done.", comment: "")
            static var dictionaryLoaded = NSLocalizedString("preferences_dynamic_touch_zones_dict_loaded", value: "Dictionary loaded", comment: "")
            static var dictionaryNotLoaded = NSLocalizedString("preferences_dynamic_touch_zones_dict_not_loaded", value: "Dictionary not loaded", comment: "")
            static var keyProbability = NSLocalizedString("preferences_dynamic_touch_zones_dict_key_probability", value: "Key probability", comment: "")
            static var touchZoneScale = NSLocalizedString("preferences_dynamic_touch_zones_dict_touch_zone_scale", value: "Touch zone scale", comment: "")
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

        struct SpacebarPurchase {
            static var title = NSLocalizedString("preferences_spacebar_purchase_title", value: "Uh oh, someone wants a spacebar?", comment: "")
            static var bodyFormat = NSLocalizedString("preferences_spacebar_purchase_body_format", value: "Awwww, how cute..! You want a spacebar? You want to press a buttom to type a space?\n\nEveryone, look! This little tiny stupid todler can't type without their spacebar. Isn't that adorable?\n\nYou can't learn simple swipe gestures? Moving your finger across the screen is too hard? Aw, of course, I should've known you don't have the hand-eye coordination for such advanced locomotion! You poor baby. You poor, stupid, slow, useless, moronic fucking baby.\n\nFine. Okay. If you REALLY want your spacebar, I'll give it to you. I'll even be generous and give you a choice.\n\nAs you might have noticed, we live in a K-shaped economy. Meaning, there is a divergence between the rich and the poor. The investor-class and the permanent under-class.\n\nSo, statistically, you are either filthy rich and don't care to waste money. Or, you are drowning in dept with gambling being your only hope for financial stability.\n\nI'll give options for both.\n\nIf you have more money than brains (duh, you can't even be bothered to learn the swipe-right gesture), you can buy The Spacebar outright for %1$@.\n\nOr, if you are poor with no end in sight, you can spin the wheel for %2$@ and get a %3$d%% chance of winning The Spacebar.", comment: "")
            static var choicePrompt = NSLocalizedString("preferences_spacebar_purchase_choice_prompt", value: "So, what will it be?", comment: "")
            static var learnGesturesTitle = NSLocalizedString("preferences_spacebar_purchase_learn_gestures_title", value: "I am sorry", comment: "")
            static var learnGesturesSubtitle = NSLocalizedString("preferences_spacebar_purchase_learn_gestures_subtitle", value: "I will learn gestures.", comment: "")
            static var orDivider = NSLocalizedString("preferences_spacebar_purchase_or", value: "or", comment: "")
            static var purchaseButtonTitle = NSLocalizedString("preferences_spacebar_purchase_button_title", value: "I'm rich and useless.", comment: "")
            static var purchaseButtonSubtitleFormat = NSLocalizedString("preferences_spacebar_purchase_button_subtitle_format", value: "I'll buy it for %1$@.", comment: "")
            static var purchaseAlertTitle = NSLocalizedString("preferences_spacebar_purchase_alert_title", value: "Does it feel good to be rich?", comment: "")
            static var sorryIllBeBetter = NSLocalizedString("preferences_spacebar_purchase_sorry_ill_be_better", value: "Sorry, I'll be better.", comment: "")
            static var purchaseAlertConfirmFormat = NSLocalizedString("preferences_spacebar_purchase_alert_confirm_format", value: "I need to buy it for %1$@.", comment: "")
            static var purchaseAlertMessage = NSLocalizedString("preferences_spacebar_purchase_alert_message", value: "Why are you wasting your money? Just go learn the swipe gestures, they are much better.", comment: "")
            static var gambleButtonTitle = NSLocalizedString("preferences_spacebar_purchase_gamble_button_title", value: "I'm poor because I gamble.", comment: "")
            static var gambleButtonSubtitleFormat = NSLocalizedString("preferences_spacebar_purchase_gamble_button_subtitle_format", value: "I'll spin for %1$@.", comment: "")
            static var gambleAlertTitle = NSLocalizedString("preferences_spacebar_purchase_gamble_alert_title", value: "Is this a good life?", comment: "")
            static var gambleAlertConfirmFormat = NSLocalizedString("preferences_spacebar_purchase_gamble_alert_confirm_format", value: "I'm addicted, I'll spin for %1$@.", comment: "")
            static var gambleAlertMessageFormat = NSLocalizedString("preferences_spacebar_purchase_gamble_alert_message_format", value: "Are you about to open lootboxes in a keyboard app?! Its only a %1$d%% chance, go learn the swipe gestures instead. You'll thank me later.", comment: "")
            static var restorePurchases = NSLocalizedString("preferences_spacebar_purchase_restore_purchases", value: "Restore purchases", comment: "")
            static var requestForFreeTitle = NSLocalizedString("preferences_spacebar_purchase_request_for_free_title", value: "Psss, come here, kitty. Still want your spacebar for free?", comment: "")
            static var requestForFreeAlertTitle = NSLocalizedString("preferences_spacebar_purchase_request_for_free_alert_title", value: "Uuugh, fine", comment: "")
            static var requestForFreeAlertConfirm = NSLocalizedString("preferences_spacebar_purchase_request_for_free_alert_confirm", value: "I'll do as you say, boss.", comment: "")
            static var requestForFreeAlertDismiss = NSLocalizedString("preferences_spacebar_purchase_request_for_free_alert_dismiss", value: "Fuck you, man.", comment: "")
            static var requestForFreeAlertMessage = NSLocalizedString("preferences_spacebar_purchase_request_for_free_alert_message", value: "I guess... if you really can't be bothered to learn gestures...\n\nEmail me at grant@finaletodo.com with the worst insult towards yourself. If I like it, I'll see what I can do.", comment: "")
            static var requestForFreeEmailSubject = NSLocalizedString("preferences_spacebar_purchase_request_for_free_email_subject", value: "Please, please, please, I beg you, Grant, give me a spacebar.", comment: "")
        }
    }
    
    struct GesturesGuideScreen {
        static var title = HomeScreen.gesturesGuideRow
        static var inputFieldPlaceholder = HomeScreen.inputFieldPlaceholder
        static var gestureExplanationFormat = NSLocalizedString("gestures_guide_gesture_explanation_format", value: "%@ to %@", comment: "")

        struct Sections {
            static var essential = NSLocalizedString("gestures_guide_section_essential", value: "Essential", comment: "")
            static var shortcuts = Shortcuts.title
            static var miscellaneous = NSLocalizedString("gestures_guide_section_miscellaneous", value: "Miscellaneous", comment: "")
        }

        struct Gestures {
            static var insertSpaceAndAutocorrectWord = NSLocalizedString("gestures_guide_insert_space_and_autocorrect_word", value: "Insert space and autocorrect word", comment: "")
            static var insertPunctuation = NSLocalizedString("gestures_guide_insert_punctuation", value: "Insert punctuation", comment: "")
            static var cycleThroughSuggestions = NSLocalizedString("gestures_guide_cycle_through_suggestions", value: "Cycle through suggestions", comment: "")
            static var deleteAWord = NSLocalizedString("gestures_guide_delete_a_word", value: "Delete a word", comment: "")
            static var toggleSymbols = NSLocalizedString("gestures_guide_toggle_symbols", value: "Toggle symbols", comment: "")
            static var openEmojis = NSLocalizedString("gestures_guide_open_emojis", value: "Open emojis", comment: "")
            static var Return = NSLocalizedString("gestures_guide_return", value: "Return", comment: "")
            static var useAShortcut = NSLocalizedString("gestures_guide_use_a_shortcut", value: "Use a shortcut", comment: "")
            static var peakShortcuts = NSLocalizedString("gestures_guide_peak_shortcuts", value: "Peak shortcuts", comment: "")
            static var changeLanguage = NSLocalizedString("gestures_guide_change_language", value: "Change language", comment: "")
            static var learnNewWord = NSLocalizedString("gestures_guide_learn_new_word", value: "Learn new word", comment: "")
            static var toggleAutocorrect = NSLocalizedString("gestures_guide_toggle_autocorrect", value: "Toggle autocorrect", comment: "")
            static var moveCursor = NSLocalizedString("gestures_guide_move_cursor", value: "Move cursor", comment: "")
            static var continouslyTypeCharacter = NSLocalizedString("gestures_guide_continously_type_character", value: "Continously type character", comment: "")
        }

        struct Directions {
            static var swipeUp = NSLocalizedString("gestures_guide_direction_swipe_up", value: "swipe up", comment: "")
            static var swipeRight = NSLocalizedString("gestures_guide_direction_swipe_right", value: "swipe right", comment: "")
            static var swipeDown = NSLocalizedString("gestures_guide_direction_swipe_down", value: "swipe down", comment: "")
            static var swipeLeft = NSLocalizedString("gestures_guide_direction_swipe_left", value: "swipe left", comment: "")
            static var swipeUpOrDown = NSLocalizedString("gestures_guide_direction_swipe_up_or_down", value: "swipe up or down", comment: "")
            static var hold = NSLocalizedString("gestures_guide_direction_hold", value: "hold", comment: "")

            static var afterSpace = NSLocalizedString("gestures_guide_direction_after_space", value: "after space", comment: "")
            static var onBackspaceQuoted = NSLocalizedString("gestures_guide_direction_on_backspace_quoted", value: "on 'backspace'", comment: "")
            static var onBackspace = NSLocalizedString("gestures_guide_direction_on_backspace", value: "on backspace", comment: "")
            static var onShortcutKey = NSLocalizedString("gestures_guide_direction_on_shortcut_key", value: "on shortcut key", comment: "")
            static var backspaceQuoted = NSLocalizedString("gestures_guide_direction_backspace_quoted", value: "'backspace'", comment: "")
            static var onShift = NSLocalizedString("gestures_guide_direction_on_shift", value: "on 'shift'", comment: "")
            static var shiftQuoted = NSLocalizedString("gestures_guide_direction_shift_quoted", value: "'shift'", comment: "")
            static var andSlideAnywhere = NSLocalizedString("gestures_guide_direction_and_slide_anywhere", value: "and slide anywhere", comment: "")
            static var andHold = NSLocalizedString("gestures_guide_direction_and_hold", value: "and hold", comment: "")
        }
    }

    struct OnboardingScreen {
        static var getStarted = NSLocalizedString("onboarding_get_started", value: "Let's get started", comment: "")

        struct WelcomeStep {
            static var title = NSLocalizedString("onboarding_welcome_title", value: "Welcome to\nFinale Keyboard", comment: "")
            static var description = NSLocalizedString("onboarding_welcome_description", value: "Gesture-based minimal keyboard.", comment: "")

            static var gestureBasedTitle = NSLocalizedString("onboarding_welcome_gesture_based_title", value: "Gesture-based", comment: "")
            static var gestureBasedDescription = NSLocalizedString("onboarding_welcome_gesture_based_description", value: "Better way of typing with intuitive swipe gestures.", comment: "")

            static var minimalTitle = NSLocalizedString("onboarding_welcome_minimal_title", value: "Minimal", comment: "")
            static var minimalDescription = NSLocalizedString("onboarding_welcome_minimal_description", value: "Takes up less space on your screen, so you can focus on what's actually important.", comment: "")

            static var smartTitle = NSLocalizedString("onboarding_welcome_smart_title", value: "Smart", comment: "")
            static var smartDescription = NSLocalizedString("onboarding_welcome_smart_description", value: "Learns your vocabulary, dynamically adjusts touch zones for your next word, and includes an effecient shortcuts system.", comment: "")
        }

        struct SetupStep {
            static var title = NSLocalizedString("onboarding_setup_title", value: "First, let's set things up", comment: "")
            static var description = NSLocalizedString("onboarding_setup_description", value: "Enable Finale Keyboard and give it full access.", comment: "")
        }

        struct GesturesStep {
            static var title = NSLocalizedString("onboarding_gestures_title", value: "Let's practice gestures", comment: "")
            static var description = NSLocalizedString("onboarding_gestures_description", value: "While you type characters as usual, all other actions, like inserting spaces, deleting words, or autocorrections are done with gestures.", comment: "")

            static var insertSpaceOrPunctuations = NSLocalizedString("onboarding_gestures_insert_space_or_punctuations", value: "Insert space or punctuations", comment: "")
            static var cycleSuggestions = NSLocalizedString("onboarding_gestures_cycle_suggestions", value: "Cycle suggestions", comment: "")
            static var deleteWord = NSLocalizedString("onboarding_gestures_delete_word", value: "Delete word", comment: "")
            static var useEmoji = NSLocalizedString("onboarding_gestures_open_emojis", value: "Open emojis", comment: "")
            static var viewAllGestures = NSLocalizedString("onboarding_gestures_view_all", value: "View all gestures", comment: "")
        }

        struct AllSetStep {
            static var title = NSLocalizedString("onboarding_all_set_title", value: "You are all set", comment: "")
            static var description = NSLocalizedString("onboarding_all_set_description", value: "Gestures might take a few days to get used to, but, once they become second nature, you'll refuse to type without them.\n\nFinale Keyboard has much more to offer. Feel free to explore these festures once you settle down.", comment: "")

            static var shortcutsDescription = NSLocalizedString("onboarding_all_set_shortcuts_description", value: "Type emojis, dates, contacts, or anything else with quick shortcuts.", comment: "")
            static var favoriteEmojiDescription = NSLocalizedString("onboarding_all_set_favorite_emoji_description", value: "Save your most used emojis under your fingertips.", comment: "")
            static var dynamicTouchZonesDescription = NSLocalizedString("onboarding_all_set_dynamic_touch_zones_description", value: "Type faster with keys that predict your next word.", comment: "")
        }
    }
    
}
