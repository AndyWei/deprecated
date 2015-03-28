//
//  JYAutocompleteTextField.m
//  joyyios
//
//  Created by Ping Yang on 3/27/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYAutocompleteTextField.h"

@interface JYAutocompleteTextField ()

@property (nonatomic, strong) NSString *autocompleteString;

@end

@implementation JYAutocompleteTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _autocompleteType = 0;
        [self setupAutocompleteTextField];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        _autocompleteType = 0;
        [self setupAutocompleteTextField];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self];
}

- (void)setupAutocompleteTextField
{
    self.autocompleteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.autocompleteLabel.font = self.font;
    self.autocompleteLabel.backgroundColor = [UIColor clearColor];
    self.autocompleteLabel.textColor = [UIColor lightGrayColor];

    self.autocompleteLabel.lineBreakMode = NSLineBreakByClipping;
    self.autocompleteLabel.hidden = YES;
    [self addSubview:self.autocompleteLabel];
    [self bringSubviewToFront:self.autocompleteLabel];

    self.autocompleteString = @"";
    
    self.ignoreCase = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:self];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self.autocompleteLabel setFont:font];
}

#pragma mark - UIResponder

- (BOOL)becomeFirstResponder
{
    if (self.autocompleteType != JYAutoCompleteTypeNone)
    {
        if ([self clearsOnBeginEditing])
        {
            self.autocompleteLabel.text = @"";
        }
        
        self.autocompleteLabel.hidden = NO;
    }
    
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    if (self.autocompleteType != JYAutoCompleteTypeNone)
    {
        self.autocompleteLabel.hidden = YES;

        if ([self commitAutocompleteText])
        {
            // This is necessary because committing the autocomplete text changes the text field's text, but for some reason UITextField doesn't post the UITextFieldTextDidChangeNotification notification on its own
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
        }
    }
    return [super resignFirstResponder];
}

#pragma mark - Autocomplete Logic

- (CGRect)autocompleteRectForBounds:(CGRect)bounds
{
    CGRect returnRect = CGRectZero;
    CGRect textRect = [self textRectForBounds:self.bounds];

    NSLineBreakMode lineBreakMode = NSLineBreakByCharWrapping;

    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = lineBreakMode;

    NSDictionary *attributes = @{NSFontAttributeName: self.font,
                                 NSParagraphStyleAttributeName: paragraphStyle};
    CGRect prefixTextRect = [self.text boundingRectWithSize:textRect.size
                                                    options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                 attributes:attributes context:nil];
    CGSize prefixTextSize = prefixTextRect.size;

    CGRect autocompleteTextRect = [self.autocompleteString boundingRectWithSize:CGSizeMake(textRect.size.width-prefixTextSize.width, textRect.size.height)
                                                                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                     attributes:attributes context:nil];
    CGSize autocompleteTextSize = autocompleteTextRect.size;
    
    returnRect = CGRectMake(textRect.origin.x + prefixTextSize.width + self.autocompleteTextOffset.x,
                            textRect.origin.y + self.autocompleteTextOffset.y,
                            autocompleteTextSize.width,
                            textRect.size.height);
    
    return returnRect;
}

- (void)updateAutocompleteLabel
{
    [self.autocompleteLabel setText:self.autocompleteString];
    [self.autocompleteLabel sizeToFit];
    [self.autocompleteLabel setFrame: [self autocompleteRectForBounds:self.bounds]];
	
	if ([self.autoCompleteTextFieldDelegate respondsToSelector:@selector(autocompleteTextField:didChangeAutocompleteText:)])
    {
		[self.autoCompleteTextFieldDelegate autocompleteTextField:self didChangeAutocompleteText:self.autocompleteString];
	}
}

- (void)refreshAutocompleteText
{
    if (self.autocompleteType != JYAutoCompleteTypeNone) {
        id <JYAutocompleteDataSource> dataSource = nil;
        
        if ([self.autocompleteDataSource respondsToSelector:@selector(textField:completionForPrefix:ignoreCase:)])
        {
            dataSource = (id <JYAutocompleteDataSource>)self.autocompleteDataSource;
        }
        
        if (dataSource) {
            self.autocompleteString = [dataSource textField:self completionForPrefix:self.text ignoreCase:self.ignoreCase];

            [self updateAutocompleteLabel];
        }
    }
}

- (BOOL)commitAutocompleteText
{
    NSString *currentText = self.text;
    if ([self.autocompleteString isEqualToString:@""] == NO
        && self.autocompleteType != JYAutoCompleteTypeNone)
    {
        self.text = [NSString stringWithFormat:@"%@%@", self.text, self.autocompleteString];
        
        self.autocompleteString = @"";
        [self updateAutocompleteLabel];
		
		if ([self.autoCompleteTextFieldDelegate respondsToSelector:@selector(autoCompleteTextFieldDidAutoComplete:)])
        {
			[self.autoCompleteTextFieldDelegate autoCompleteTextFieldDidAutoComplete:self];
		}
    }
    return ![currentText isEqualToString:self.text];
}

- (void)textDidChange:(NSNotification*)notification
{
    [self refreshAutocompleteText];
}

- (void)forceRefreshAutocompleteText
{
    [self refreshAutocompleteText];
}


@end
