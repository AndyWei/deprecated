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

@class JYAutoCompleteTextField;

@protocol JYAutoCompleteDataSourceDelegate <NSObject>

- (NSString *)textField:(JYAutoCompleteTextField *)textField completionForPrefix:(NSString *)prefix ignoreCase:(BOOL)ignoreCase;

@end

@protocol JYAutoCompleteTextFieldDelegate <NSObject>

@optional
- (void)autoCompleteTextFieldDidAutoComplete:(JYAutoCompleteTextField *)autoCompleteField;
- (void)autocompleteTextField:(JYAutoCompleteTextField *)autocompleteTextField didChangeAutocompleteText:(NSString *)autocompleteText;

@end

@interface JYAutoCompleteTextField : UITextField

/*
 * Autocomplete behavior
 */
@property(nonatomic) JYAutoCompleteType autocompleteType; // default to JYAutoCompleteTypeNone
@property(nonatomic) BOOL ignoreCase;
@property(nonatomic, weak) id<JYAutoCompleteTextFieldDelegate> autoCompleteTextFieldDelegate;

/*
 * Configure text field appearance
 */
@property(nonatomic) UILabel *autocompleteLabel;
@property(nonatomic) CGPoint autocompleteTextOffset;

/*
 * Specify a data source responsible for determining autocomplete text.
 */
@property(nonatomic) id<JYAutoCompleteDataSourceDelegate> autocompleteDataSource;

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