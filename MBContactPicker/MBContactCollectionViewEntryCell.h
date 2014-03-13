//
//  ContactEntryCollectionViewCell.h
//  MBContactPicker
//
//  Created by Matt Bowman on 11/21/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UITextFieldDelegateImproved <UITextFieldDelegate>

- (void)textFieldDidChange:(UITextField*)textField;

@end

@interface MBContactCollectionViewEntryCell : UICollectionViewCell

@property (nonatomic, weak) id<UITextFieldDelegateImproved> delegate;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *promptPlaceholder;
@property (nonatomic) BOOL enabled;

@property (nonatomic, copy) UIFont *font;
@property (nonatomic, copy) UIColor *placeholderColor;
@property (nonatomic, copy) UIColor *textColor;

@property (nonatomic, assign) BOOL namesAdded;

- (void)setFocus;
- (void)removeFocus;
- (void)reset;
- (CGFloat)widthForText:(NSString*)text;

@end
