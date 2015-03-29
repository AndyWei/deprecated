//
//  JYAutocompleteTextField.h
//  joyyios
//
//  Created by Ping Yang on 3/27/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef enum
{
    JYAutoCompleteTypeNone,
    JYAutoCompleteTypeEmail,
    JYAutoCompleteTypeColor
} JYAutoCompleteType;

@class JYAutocompleteTextField;

@protocol JYAutocompleteDataSource <NSObject>

- (NSString *)textField:(JYAutocompleteTextField *)textField completionForPrefix:(NSString *)prefix ignoreCase:(BOOL)ignoreCase;

@end

@protocol JYAutocompleteTextFieldDelegate <NSObject>

@optional
- (void)autoCompleteTextFieldDidAutoComplete:(JYAutocompleteTextField *)autoCompleteField;
- (void)autocompleteTextField:(JYAutocompleteTextField *)autocompleteTextField didChangeAutocompleteText:(NSString *)autocompleteText;

@end

@interface JYAutocompleteTextField : UITextField

/*
 * Autocomplete behavior
 */
@property(nonatomic, assign) JYAutoCompleteType autocompleteType; // default to JYAutoCompleteTypeNone
@property(nonatomic, assign) BOOL ignoreCase;
@property(nonatomic, assign) id<JYAutocompleteTextFieldDelegate> autoCompleteTextFieldDelegate;

/*
 * Configure text field appearance
 */
@property(nonatomic, strong) UILabel *autocompleteLabel;
@property(nonatomic, assign) CGPoint autocompleteTextOffset;

/*
 * Specify a data source responsible for determining autocomplete text.
 */
@property(nonatomic, assign) id<JYAutocompleteDataSource> autocompleteDataSource;

/*
 * Subclassing:
 */
- (CGRect)autocompleteRectForBounds:(CGRect)bounds; // Override to alter the position of the autocomplete text
- (void)setupAutocompleteTextField;                 // Override to perform setup tasks.  Don't forget to call super.

/*
 * Refresh the autocomplete text manually (useful if you want the text to change while the user isn't editing the text)
 */
- (void)forceRefreshAutocompleteText;

@end