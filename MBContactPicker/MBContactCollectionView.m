//
//  ContactCollectionView.m
//  MBContactPicker
//
//  Created by Matt Bowman on 11/20/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import "MBContactCollectionView.h"
#import "MBContactCollectionViewEntryCell.h"
#import "MBContactCollectionViewPromptCell.h"
#import "MBContactCollectionViewFlowLayout.h"

NSInteger const kCellHeight = 31;
NSString * const kPrompt = @"To:";
NSString * const kDefaultEntryText = @" ";

@interface MBContactCollectionView() <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegateImproved, MBContactCollectionViewDelegateFlowLayout, UIKeyInput>

@property (nonatomic, readonly) NSIndexPath *indexPathOfSelectedCell;
@property (nonatomic) MBContactCollectionViewContactCell *prototypeCell;
@property (nonatomic) MBContactCollectionViewPromptCell *promptCell;
@property (nonatomic) NSString *searchText;
@property (nonatomic, readonly) NSIndexPath *entryCellIndexPath;

@end

typedef NS_ENUM(NSInteger, ContactCollectionViewSection) {
    ContactCollectionViewSectionPrompt,
    ContactCollectionViewSectionContact,
    ContactCollectionViewSectionEntry
};

@implementation MBContactCollectionView

+ (MBContactCollectionView*)contactCollectionViewWithFrame:(CGRect)frame
{
    MBContactCollectionViewFlowLayout *layout = [[MBContactCollectionViewFlowLayout alloc] init];
    return [[self alloc] initWithFrame:frame collectionViewLayout:layout];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    CGFloat origWidth = self.frame.size.width;
    
    [super setFrame:frame];
    
    [self handleWidthChangeFrom:origWidth to:frame.size.width];
}

- (void)setBounds:(CGRect)bounds
{
    CGFloat origWidth = self.bounds.size.width;
    
    [super setBounds:bounds];
    
    [self handleWidthChangeFrom:origWidth to:bounds.size.width];
}

- (void)handleWidthChangeFrom:(CGFloat)oldWidth to:(CGFloat)newWidth
{
    if (oldWidth != newWidth)
    {
        [self forceRelayout];
    }
}

- (void)reset {

    MBContactCollectionViewEntryCell *cell = [self cellForItemAtIndexPath:self.entryCellIndexPath];
    [cell reset];
}

- (void)forceRelayout
{
    // * Technique taken from http://stackoverflow.com/a/13656570
    //
    // -[UICollectionViewLayout invalidateLayout] causes the layout to recalculate the layout of the cells, but it doesn't cause the
    // size of the cells to be requeried via `collectionView:layout:sizeForItemAtIndexPath:`.  `performBatchUpdates:completion:`,
    // however, causes both an `invalidateLayout` and a the cell sizes to be requeried, which is exactly what we want.
    [self performBatchUpdates:nil completion:nil];
}

- (void)setup
{
    self.selectedContacts = [[NSMutableArray alloc] init];
    
    self.cellHeight = kCellHeight;
    _prompt = NSLocalizedStringWithDefaultValue(@"MBContactPickerPrompt", nil, [NSBundle mainBundle], kPrompt, @"Prompt text shown in the prompt cell");
    self.searchText = kDefaultEntryText;
    self.allowsTextInput = YES;
    _showPrompt = YES;
    
    MBContactCollectionViewFlowLayout *layout = (MBContactCollectionViewFlowLayout*)self.collectionViewLayout;
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 1;
    layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    
    self.prototypeCell = [[MBContactCollectionViewContactCell alloc] init];
    
    self.allowsMultipleSelection = NO;
    self.allowsSelection = YES;
    self.backgroundColor = [UIColor whiteColor];
    
    [self registerClass:[MBContactCollectionViewContactCell class] forCellWithReuseIdentifier:@"ContactCell"];
    [self registerClass:[MBContactCollectionViewEntryCell class] forCellWithReuseIdentifier:@"ContactEntryCell"];
    [self registerClass:[MBContactCollectionViewPromptCell class] forCellWithReuseIdentifier:@"ContactPromptCell"];
    
    self.dataSource = self;
    self.delegate = self;
}

#pragma mark - Properties

- (CGFloat)maxContentWidth
{
    UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout*)self.collectionViewLayout).sectionInset;
    return self.frame.size.width - sectionInset.left - sectionInset.right;
}

- (void)setAllowsTextInput:(BOOL)allowsTextInput
{
    _allowsTextInput = allowsTextInput;
    
    if([self.indexPathsForVisibleItems containsObject:self.entryCellIndexPath] && self.entryCellIndexPath)
    {
        [self reloadItemsAtIndexPaths:@[self.entryCellIndexPath]];
    }
}

- (NSIndexPath*)entryCellIndexPath
{
    return [NSIndexPath indexPathForRow:self.selectedContacts.count + (self.showPrompt ? 1 : 0) inSection:0];
}

- (void)setShowPrompt:(BOOL)showPrompt
{
    if (_showPrompt == showPrompt)
    {
        return;
    }
    
    _showPrompt = showPrompt;
    
    // If there aren't any visible cells, then one of the following is true:
    //
    // 1)   -[UICollectionView reloadData] hasn't yet been called.  In that case, calling `insertItemsAtIndexPaths:` or
    //      `deleteItemsAtIndexPaths:` could cause undesired behavior.
    // 2)   There really aren't any cells.  This shouldn't happen since, at a minimum, the entry cell should be present.
    if (self.visibleCells.count == 0)
    {
        return;
    }
    
    if (_showPrompt)
    {
        [self insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
    else
    {
        [self deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
}

- (void)setPrompt:(NSString *)prompt
{
    _prompt = prompt.copy;
    
    // If there aren't any visible cells, then one of the following is true:
    //
    // 1)   -[UICollectionView reloadData] hasn't yet been called.  In that case, calling `reloadItemsAtIndexPaths:` could cause undesired behavior.
    // 2)   There really aren't any cells.  This shouldn't happen since, at a minimum, the entry cell should be present.
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
}

- (void)setPromptImage:(UIImage *)promptImage {
    _promptImage = promptImage.copy;
    
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
}

- (void)setPromptPlaceholder:(NSString *)promptPlaceholder {
    _promptPlaceholder = promptPlaceholder.copy;
    
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadItemsAtIndexPaths:@[self.entryCellIndexPath]];
    }
}

- (void)setFont:(UIFont *)font {
    _font = font.copy;
    
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadData];
    }

}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor.copy;
    
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadData];
    }

}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor.copy;
    
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadData];
    }

}

- (void)setSelectedColor:(UIColor *)selectedColor {
    _selectedColor = selectedColor;
    
    if (self.showPrompt && self.visibleCells.count > 0)
    {
        [self reloadData];
    }

}

#pragma mark - UIResponder

// Important to return YES here if we want to become the first responder after a child (i.e., entry UITextField)
// has given it up so we can respond to keyboard events

// For Tanner's version we want to check to see if an item is selected.

- (BOOL)canBecomeFirstResponder
{
    NSArray *array = self.indexPathsForSelectedItems;
    
    if ([self.indexPathsForSelectedItems count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)resignFirstResponder
{
    if (self.indexPathsForSelectedItems.count > 0)
    {
        for (NSIndexPath *indexPath in self.indexPathsForSelectedItems) {
            [self deselectItemAtIndexPath:indexPath animated:YES];
            [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
        }
    }
    
    [self removeFocusFromEntry];
    
    [super resignFirstResponder];
    
    return YES;
}

#pragma mark - UIKeyInput

- (void) deleteBackward
{
    if ([self indexPathsForSelectedItems].count > 0)
    {
        [self removeFromSelectedContacts:[self selectedContactIndexFromRow:self.indexPathOfSelectedCell.row] withCompletion:nil];
    }
}

- (BOOL)hasText
{
    return YES;
}

- (void)insertText:(NSString *)text
{
}

#pragma mark - Helper Methods

- (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model withCompletion:(void(^)())completion
{
    MBContactCollectionViewEntryCell *entryCell = (MBContactCollectionViewEntryCell *)[self cellForItemAtIndexPath:[self entryCellIndexPath]];

    if ([[self indexPathsForVisibleItems] containsObject:self.entryCellIndexPath])
    {
        [entryCell reset];
    }
    else
    {
        self.searchText = kDefaultEntryText;
    }
    
    if (![self.selectedContacts containsObject:model])
    {
        [self.selectedContacts addObject:model];
        CGPoint originalOffset = self.contentOffset;
        [self performBatchUpdates:^{
            [self insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.selectedContacts.count - (self.showPrompt ? 0 : 1) inSection:0]]];
            self.contentOffset = originalOffset;
        } completion:^(BOOL finished) {
            if (completion)
            {
                completion();
            }
            if ([self.contactDelegate respondsToSelector:@selector(contactCollectionView:didAddContact:)])
            {
                [self.contactDelegate contactCollectionView:self didAddContact:model];
            }
            
            entryCell.namesAdded = ([self.selectedContacts count] > 0);
        }];
    }
    
}

- (void)removeFromSelectedContacts:(NSInteger)index withCompletion:(void(^)())completion
{
    if (self.selectedContacts.count + 1 > self.indexPathsForSelectedItems.count)
    {
        id<MBContactPickerModelProtocol> model = (id<MBContactPickerModelProtocol>)self.selectedContacts[index];
        [self performBatchUpdates:^{
            [self.selectedContacts removeObjectAtIndex:index];
            [self deselectItemAtIndexPath:self.indexPathOfSelectedCell animated:NO];
            [self deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index + (self.showPrompt ? 1 : 0) inSection:0]]];
            [self scrollToItemAtIndexPath:[self entryCellIndexPath] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
        } completion:^(BOOL finished) {
            if (completion)
            {
                completion();
            }
            if ([self.contactDelegate respondsToSelector:@selector(contactCollectionView:didRemoveContact:)])
            {
                [self.contactDelegate contactCollectionView:self didRemoveContact:model];
            }

            MBContactCollectionViewEntryCell *entryCell = (MBContactCollectionViewEntryCell *)[self cellForItemAtIndexPath:[self entryCellIndexPath]];
            entryCell.namesAdded = ([self.selectedContacts count] > 0);

            [self setFocusOnEntry];
        }];
    }
}

- (BOOL)isEntryCell:(NSIndexPath*)indexPath
{
    return indexPath.row == [self entryCellIndex];
}

- (BOOL)isPromptCell:(NSIndexPath*)indexPath
{
    return self.showPrompt && indexPath.row == 0;
}

- (BOOL)isContactCell:(NSIndexPath*)indexPath
{
    return ![self isPromptCell:indexPath] && ![self isEntryCell:indexPath];
}

- (NSInteger)entryCellIndex
{
    return self.selectedContacts.count + (self.showPrompt ? 1 : 0);
}

- (NSInteger)selectedContactIndexFromIndexPath:(NSIndexPath*)indexPath
{
    return [self selectedContactIndexFromRow:indexPath.row];
}

- (NSInteger)selectedContactIndexFromRow:(NSInteger)row
{
    return row - (self.showPrompt ? 1 : 0);
}

- (NSIndexPath*)indexPathOfSelectedCell
{
    if (self.indexPathsForSelectedItems.count > 0)
    {
        return (NSIndexPath*)self.indexPathsForSelectedItems[0];
    }
    else
    {
        return nil;
    }
}

- (void)setFocusOnEntry
{
    if ([self entryIsVisible])
    {
        MBContactCollectionViewEntryCell *entryCell = (MBContactCollectionViewEntryCell *)[self cellForItemAtIndexPath:[self entryCellIndexPath]];
        [entryCell setFocus];
    }
    else
    {
        [self scrollToEntryAnimated:YES onComplete:^{
            MBContactCollectionViewEntryCell *entryCell = (MBContactCollectionViewEntryCell *)[self cellForItemAtIndexPath:[self entryCellIndexPath]];
            [entryCell setFocus];
        }];
    }
}

- (void)removeFocusFromEntry
{
    MBContactCollectionViewEntryCell *entryCell = (MBContactCollectionViewEntryCell *)[self cellForItemAtIndexPath:[self entryCellIndexPath]];
    [entryCell removeFocus];
}

- (BOOL)entryIsVisible
{
    return [[self indexPathsForVisibleItems] containsObject:[self entryCellIndexPath]];
}

- (void)scrollToEntryAnimated:(BOOL)animated onComplete:(void(^)())complete
{
    if (animated)
    {
        [UIView animateWithDuration:.25
                         animations:^{
                             self.contentOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
                         }
                         completion:^(BOOL finished) {
                             if (complete)
                             {
                                 complete();
                             }
                         }];
    }
    else if (self.showPrompt)
    {
        [self scrollToItemAtIndexPath:[self entryCellIndexPath]
                     atScrollPosition:UICollectionViewScrollPositionBottom
                             animated:NO];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBContactCollectionViewContactCell *cell = (MBContactCollectionViewContactCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self becomeFirstResponder];
    cell.focused = YES;
    
    if ([self.contactDelegate respondsToSelector:@selector(contactCollectionView:didSelectContact:)])
    {
        [self.contactDelegate contactCollectionView:self didSelectContact:cell.model];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self isContactCell:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBContactCollectionViewContactCell *cell = (MBContactCollectionViewContactCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.focused = NO;
}

#pragma mark - UICollectionViewDelegateContactFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat widthForItem;
    
    if ([self isPromptCell:indexPath])
    {
        widthForItem = [MBContactCollectionViewPromptCell widthWithPrompt:self.prompt image:self.promptImage];
        widthForItem += 20;
    }
    else if ([self isEntryCell:indexPath])
    {
        MBContactCollectionViewEntryCell *prototype = [[MBContactCollectionViewEntryCell alloc] init];
        widthForItem = MAX(50, [prototype widthForText:self.searchText]);
    }
    else
    {
        id<MBContactPickerModelProtocol> model = self.selectedContacts[[self selectedContactIndexFromIndexPath:indexPath]];
        widthForItem = [self.prototypeCell widthForCellWithContact:model];
    }
    
    return CGSizeMake(MIN([self maxContentWidth], widthForItem), self.cellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView willChangeContentSizeTo:(CGSize)newSize
{
    if ([self.contactDelegate respondsToSelector:@selector(contactCollectionView:willChangeContentSizeTo:)])
    {
        [self.contactDelegate contactCollectionView:self willChangeContentSizeTo:newSize];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.selectedContacts.count + (self.showPrompt ? 1 : 0) + 1;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *collectionCell;
    
    if ([self isPromptCell:indexPath])
    {
        MBContactCollectionViewPromptCell *cell = (MBContactCollectionViewPromptCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"ContactPromptCell" forIndexPath:indexPath];
        cell.prompt = self.prompt;
        cell.promptImage = self.promptImage;
        collectionCell = cell;
        self.promptCell = cell;
    }
    else if ([self isEntryCell:indexPath])
    {
        MBContactCollectionViewEntryCell *cell = (MBContactCollectionViewEntryCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"ContactEntryCell"
                                                                                                                               forIndexPath:indexPath];
        if ([self.selectedContacts count] == 0) {
            cell.promptPlaceholder = self.promptPlaceholder;
        } else {
            cell.promptPlaceholder = @"";
        }
        cell.font = self.font;
        cell.placeholderColor = self.placeholderColor;
        cell.textColor = self.textColor;
        cell.delegate = self;
        collectionCell = cell;
        
        if ([self isFirstResponder] && self.indexPathOfSelectedCell == nil)
        {
            [cell setFocus];
        }

        cell.text = self.searchText;
        cell.enabled = self.allowsTextInput;
    }
    else
    {
        MBContactCollectionViewContactCell *cell = (MBContactCollectionViewContactCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"ContactCell"
                                                                                                                forIndexPath:indexPath];
        cell.model = self.selectedContacts[[self selectedContactIndexFromIndexPath:indexPath]];
        cell.font = self.font;
        if ([self.indexPathOfSelectedCell isEqual:indexPath])
        {
            cell.focused = YES;
        }
        else
        {
            cell.focused = NO;
        }
        collectionCell = cell;
    }
    
    return collectionCell;
}

#pragma mark - UITextFieldDelegateImproved

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // If backspace is pressed and there isn't any text in the field, we want to select the
    // last selected contact and not let them delete the space we inserted (the space allows
    // us to catch the last backspace press - without it, we get no event!)
    if ([newString isEqualToString:@""] &&
        [string isEqualToString:@""] &&
        range.location == 0 &&
        range.length == 1)
    {
        if (self.selectedContacts.count > 0)
        {
            [textField resignFirstResponder];
            NSIndexPath *newSelectedIndexPath = [NSIndexPath indexPathForItem:self.selectedContacts.count - (self.showPrompt ? 0 : 1)
                                                                    inSection:0];
            [self selectItemAtIndexPath:newSelectedIndexPath
                               animated:YES
                         scrollPosition:UICollectionViewScrollPositionBottom];
            [self.delegate collectionView:self didSelectItemAtIndexPath:newSelectedIndexPath];
            [self becomeFirstResponder];
        }
        return NO;
    }
    
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    self.searchText = textField.text;
    if ([self.contactDelegate respondsToSelector:@selector(contactCollectionView:entryTextDidChange:)])
    {
        [self.contactDelegate contactCollectionView:self entryTextDidChange:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self resignFirstResponder];
    return YES;
}

+ (CGFloat)defaultHeight {
    return kCellHeight;
}

@end
