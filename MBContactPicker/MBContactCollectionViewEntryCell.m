//
//  ContactEntryCollectionViewCell.m
//  MBContactPicker
//
//  Created by Matt Bowman on 11/21/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import "MBContactCollectionViewEntryCell.h"

@interface MBContactCollectionViewEntryCell() <UITextFieldDelegate>

@property (nonatomic, weak) UITextField *contactEntryTextField;
@property (nonatomic, weak) UILabel *placeholder;


@end

@implementation MBContactCollectionViewEntryCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)setup
{
    UILabel *placeholder = [[UILabel alloc] initWithFrame:self.bounds];
    placeholder.backgroundColor = [UIColor clearColor];
    [self addSubview:placeholder];
    self.placeholder = placeholder;
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[placeholder]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(placeholder)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[placeholder]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(placeholder)]];
    self.placeholder.translatesAutoresizingMaskIntoConstraints = NO;

    
    UITextField *textField = [[UITextField alloc] initWithFrame:self.bounds];
    textField.backgroundColor = [UIColor clearColor];
    textField.delegate = self.delegate;
    textField.text = @"";
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
#ifdef DEBUG_BORDERS
    self.layer.borderColor = [UIColor orangeColor].CGColor;
    self.layer.borderWidth = 1.0;
    textField.layer.borderColor = [UIColor greenColor].CGColor;
    textField.layer.borderWidth = 2.0;
#endif
    [self addSubview:textField];
    self.contactEntryTextField = textField;

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(textField)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(textField)]];
    self.contactEntryTextField.translatesAutoresizingMaskIntoConstraints = NO;
    

    
}

- (void)setDelegate:(id<UITextFieldDelegateImproved>)delegate
{
    _delegate = delegate;
    
    [self.contactEntryTextField addTarget:delegate action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.contactEntryTextField.delegate = self;
}

- (NSString*)text
{
    return self.contactEntryTextField.text;
}

- (void)setText:(NSString *)text
{
    self.contactEntryTextField.text = text;
}

- (void)setPromptPlaceholder:(NSString *)promptPlaceholder {
    _promptPlaceholder = promptPlaceholder.copy;

    self.placeholder.text = promptPlaceholder;
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    self.contactEntryTextField.enabled = enabled;
}

- (void)setFont:(UIFont *)font {
    _font = font.copy;
    
    self.placeholder.font = font;
    self.contactEntryTextField.font = font;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor.copy;
    
    self.placeholder.textColor = placeholderColor;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor.copy;
    
    self.contactEntryTextField.textColor = textColor;
}

- (void)reset
{
    self.contactEntryTextField.text = @" ";

    [self.delegate textFieldDidChange:self.contactEntryTextField];
}

- (void)setFocus
{
    [self.contactEntryTextField becomeFirstResponder];
}

- (void)setNamesAdded:(BOOL)namesAdded {
    _namesAdded = namesAdded;
    
    if (!namesAdded) {
        self.placeholder.hidden = (self.contactEntryTextField.text.length > 1);
    } else {
        self.placeholder.hidden = YES;
    }
}

- (void)removeFocus
{
    [self.contactEntryTextField resignFirstResponder];
}

- (CGFloat)widthForText:(NSString *)text
{
    CGFloat widthText = [text boundingRectWithSize:(CGSize){ .width = CGFLOAT_MAX, .height = CGFLOAT_MAX }
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{ NSFontAttributeName: self.contactEntryTextField.font }
                                       context:nil].size.width;

    if (widthText == 0) {
    
        widthText = [self.promptPlaceholder boundingRectWithSize:(CGSize){ .width = CGFLOAT_MAX, .height = CGFLOAT_MAX }
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{ NSFontAttributeName: self.placeholder.font }
                                              context:nil].size.width;
    }
    
    return ceilf(widthText);
}

#pragma mark - Delegate Pass Throughs

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    BOOL should = YES;
    if ([_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        should = [_delegate textFieldShouldBeginEditing:textField];
    }
    
    return should;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if ([_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [_delegate textFieldDidBeginEditing:textField];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    BOOL should = YES;
    if ([_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
       should = [_delegate textFieldShouldEndEditing:textField];
    }

    return should;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        [_delegate textFieldDidEndEditing:textField];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL should = YES;
    
    if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
    
        should = [_delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
        
        if (should) {
            NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
            
            if (!self.namesAdded) {
                self.placeholder.hidden = (newText.length > 1);
            } else {
                self.placeholder.hidden = YES;
            }
        }
    }

    return should;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    BOOL should = YES;
    if ([_delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
       should = [_delegate textFieldShouldClear:textField];
    }
    
    if (!self.namesAdded) {
        if (should) {
            self.placeholder.hidden = NO;
        }
    } else {
        self.placeholder.hidden = YES;
    }

    return should;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    BOOL should = YES;
    if ([_delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        should = [_delegate textFieldShouldReturn:textField];
    }
    
    return should;
}


@end
