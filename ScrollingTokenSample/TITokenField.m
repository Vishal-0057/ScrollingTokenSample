//
//  TITokenField.m
//  TITokenField
//
//  Created by Tom Irving on 16/02/2010.
//  Copyright 2012 Tom Irving. All rights reserved.
//

#import "TITokenField.h"
#import <QuartzCore/QuartzCore.h>
#import "CustomButton.h"
#import "UIView+Genie.h"
#import "UIColor+Hex.h"

@interface TITokenField ()
@property (nonatomic, assign) BOOL forcePickSearchResult;
@end

//==========================================================
#pragma mark - TITokenFieldView -
//==========================================================

@interface TITokenFieldView (Private)
- (void)setup;
- (NSString *)displayStringForRepresentedObject:(id)object;
- (NSString *)searchResultStringForRepresentedObject:(id)object;
- (void)setSearchResultsVisible:(BOOL)visible;
- (void)resultsForSearchString:(NSString *)searchString;
- (void)presentpopoverAtTokenFieldCaretAnimated:(BOOL)animated;
@end

@implementation TITokenFieldView {
    UIView * _contentView;
    NSMutableArray * _resultsArray;
    UIPopoverController * _popoverController;
}
@dynamic delegate;
@synthesize showAlreadyTokenized = _showAlreadyTokenized;
@synthesize searchSubtitles = _searchSubtitles;
@synthesize forcePickSearchResult = _forcePickSearchResult;
@synthesize tokenField = _tokenField;
@synthesize resultsTable = _resultsTable;
@synthesize contentView = _contentView;
@synthesize separator = _separator;
@synthesize sourceArray = _sourceArray;

#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])){
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])){
        [self setup];
    }
    
    return self;
}

- (void)setup {
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self setDelaysContentTouches:YES];
    [self setMultipleTouchEnabled:NO];
    
    _showAlreadyTokenized = NO;
    _searchSubtitles = YES;
    _forcePickSearchResult = NO;
    _resultsArray = [NSMutableArray array];
    
    self.showsVerticalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    
    _tokenField = [[TITokenField alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 38)];
    [_tokenField addTarget:self action:@selector(tokenFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    [_tokenField addTarget:self action:@selector(tokenFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    [_tokenField addTarget:self action:@selector(tokenFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [_tokenField addTarget:self action:@selector(tokenFieldFrameWillChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
    [_tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
    [_tokenField setDelegate:self];
    [self addSubview:_tokenField];
    
    
    //	CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame);
    //
    //	_separator = [[UIView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom, self.bounds.size.width, 1)];
    //	[_separator setBackgroundColor:[UIColor colorWithHexString:@"e5e5e5"]];
    //	[self addSubview:_separator];
    
    // This view is created for convenience, because it resizes and moves with the rest of the subviews.
    //_contentView = [[UIView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom + 1, self.bounds.size.width,
    //													   self.bounds.size.height - tokenFieldBottom - 1)];
    //[_contentView setBackgroundColor:[UIColor clearColor]];
    //[self addSubview:_contentView];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        
        //		UITableViewController * tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        //		[tableViewController.tableView setDelegate:self];
        //		[tableViewController.tableView setDataSource:self];
        //		[tableViewController setContentSizeForViewInPopover:CGSizeMake(400, 400)];
        //
        //		_resultsTable = tableViewController.tableView;
        //
        //		_popoverController = [[UIPopoverController alloc] initWithContentViewController:tableViewController];
    }
    else
    {
        //		_resultsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom + 1, self.bounds.size.width, 10)];
        //		[_resultsTable setSeparatorColor:[UIColor colorWithWhite:0.85 alpha:1]];
        //		[_resultsTable setBackgroundColor:[UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1]];
        //		[_resultsTable setDelegate:self];
        //		[_resultsTable setDataSource:self];
        //		[_resultsTable setHidden:YES];
        //		[self addSubview:_resultsTable];
        //
        //		_popoverController = nil;
    }
    
    [self bringSubviewToFront:_separator];
    [self bringSubviewToFront:_tokenField];
    [self updateContentSize];
}

#pragma mark Property Overrides
- (void)setFrame:(CGRect)frame {
    
    [super setFrame:frame];
    
    CGFloat width = frame.size.width;
    [_separator setFrame:((CGRect){_separator.frame.origin, {width, _separator.bounds.size.height}})];
    [_resultsTable setFrame:((CGRect){_resultsTable.frame.origin, {width, _resultsTable.bounds.size.height}})];
    [_contentView setFrame:((CGRect){_contentView.frame.origin, {width, (frame.size.height - CGRectGetMaxY(_tokenField.frame))}})];
    [_tokenField setFrame:((CGRect){_tokenField.frame.origin, {width, _tokenField.bounds.size.height}})];
    
    if (_popoverController.popoverVisible){
        [_popoverController dismissPopoverAnimated:NO];
        [self presentpopoverAtTokenFieldCaretAnimated:NO];
    }
    
    //[self updateContentSize];
    [self setNeedsLayout];
}

- (void)setContentOffset:(CGPoint)offset {
    [super setContentOffset:offset];
    [self setNeedsLayout];
}

- (NSArray *)tokenTitles {
    return _tokenField.tokenTitles;
}

- (void)setForcePickSearchResult:(BOOL)forcePickSearchResult
{
    _tokenField.forcePickSearchResult = forcePickSearchResult;
    _forcePickSearchResult = forcePickSearchResult;
}

#pragma mark Event Handling
- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    CGFloat relativeFieldHeight = CGRectGetMaxY(_tokenField.frame) - self.contentOffset.y;
    CGFloat newHeight = self.bounds.size.height - relativeFieldHeight;
    if (newHeight > -1) [_resultsTable setFrame:((CGRect){_resultsTable.frame.origin, {_resultsTable.bounds.size.width, newHeight}})];
}

- (void)updateContentSize {
    [self setContentSize:CGSizeMake(self.bounds.size.width, CGRectGetMaxY(_contentView.frame) + 1)];
    //[self setContentSize:CGSizeMake(500, CGRectGetMaxY(_contentView.frame) + 1)];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return [_tokenField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [_tokenField resignFirstResponder];
}

#pragma mark TableView Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:resultsTableView:heightForRowAtIndexPath:)]){
        return [_tokenField.delegate tokenField:_tokenField resultsTableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:didFinishSearch:)]){
        [_tokenField.delegate tokenField:_tokenField didFinishSearch:_resultsArray];
    }
    
    return _resultsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id representedObject = [_resultsArray objectAtIndex:indexPath.row];
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:resultsTableView:cellForRepresentedObject:)]){
        return [_tokenField.delegate tokenField:_tokenField resultsTableView:tableView cellForRepresentedObject:representedObject];
    }
    
    static NSString * CellIdentifier = @"ResultsCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSString * subtitle = [self searchResultSubtitleForRepresentedObject:representedObject];
    
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:(subtitle ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault) reuseIdentifier:CellIdentifier];
    
    [cell.textLabel setText:[self searchResultStringForRepresentedObject:representedObject]];
    [cell.detailTextLabel setText:subtitle];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id representedObject = [_resultsArray objectAtIndex:indexPath.row];
    TIToken * token = [[TIToken alloc] initWithTitle:[self displayStringForRepresentedObject:representedObject] id:nil category:nil representedObject:representedObject];
    [_tokenField addToken:token];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self setSearchResultsVisible:NO];
}

#pragma mark TextField Methods

- (void)tokenFieldDidBeginEditing:(TITokenField *)field {
    [_resultsArray removeAllObjects];
    [_resultsTable reloadData];
}

- (void)tokenFieldDidEndEditing:(TITokenField *)field {
    [self tokenFieldDidBeginEditing:field];
}

- (void)tokenFieldTextDidChange:(TITokenField *)field {
    
    if (field.tokens.count > 0) {
        NSString *string = _tokenField.text;
        if ( [_tokenField.text length] > 1) {
            string = [_tokenField.text substringFromIndex:[_tokenField.text length] - 1];
        }
        
        CGRect frame = [string boundingRectWithSize:CGSizeMake(310, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:field.font} context:nil];
        CGSize size = frame.size;
        //CGSize size = [string sizeWithFont:field.font forWidth:310 lineBreakMode:NSLineBreakByWordWrapping];
        //    if (self.view.frame.size.w + size.width) {
        //
        //    }
        CGSize newSize = CGSizeMake((field.frame.size.width + size.width), field.frame.size.height);
        [field setFrame:(CGRect){field.frame.origin,newSize}];
        [self tokenFieldFrameWillChange:field];
    }
    
    [self resultsForSearchString:_tokenField.text];
    
    if (_forcePickSearchResult) {
        [self setSearchResultsVisible:YES];
    } else {
        [self setSearchResultsVisible:(_resultsArray.count > 0)];
    }
}

- (void)tokenFieldFrameWillChange:(TITokenField *)field {
    
    CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame);
    CGFloat tokenFieldWidth = CGRectGetWidth(_tokenField.frame);
    CGSize seperatorSize = CGSizeMake(tokenFieldWidth,_separator.frame.size.height);
    
    [self setContentSize:CGSizeMake(seperatorSize.width, CGRectGetMaxY(_contentView.frame) + 1)];
    
    [_separator setFrame:((CGRect){{_separator.frame.origin.x, tokenFieldBottom}, seperatorSize})];
    [_resultsTable setFrame:((CGRect){{_resultsTable.frame.origin.x, (tokenFieldBottom + 1)}, _resultsTable.bounds.size})];
    [_contentView setFrame:((CGRect){{_contentView.frame.origin.x, (tokenFieldBottom + 1)}, _contentView.bounds.size})];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)field {
    [self updateContentSize];
}

#pragma mark Results Methods
- (NSString *)displayStringForRepresentedObject:(id)object {
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:displayStringForRepresentedObject:)]){
        return [_tokenField.delegate tokenField:_tokenField displayStringForRepresentedObject:object];
    }
    
    if ([object isKindOfClass:[NSString class]]){
        return (NSString *)object;
    }
    
    return [NSString stringWithFormat:@"%@", object];
}

- (NSString *)searchResultStringForRepresentedObject:(id)object {
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultStringForRepresentedObject:)]){
        return [_tokenField.delegate tokenField:_tokenField searchResultStringForRepresentedObject:object];
    }
    
    return [self displayStringForRepresentedObject:object];
}

- (NSString *)searchResultSubtitleForRepresentedObject:(id)object {
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultSubtitleForRepresentedObject:)]){
        return [_tokenField.delegate tokenField:_tokenField searchResultSubtitleForRepresentedObject:object];
    }
    
    return nil;
}

- (void)setSearchResultsVisible:(BOOL)visible {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        
        if (visible) [self presentpopoverAtTokenFieldCaretAnimated:YES];
        else [_popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [_resultsTable setHidden:!visible];
        [_tokenField setResultsModeEnabled:visible];
    }
}

- (void)resultsForSearchString:(NSString *)searchString {
    
    // The brute force searching method.
    // Takes the input string and compares it against everything in the source array.
    // If the source is massive, this could take some time.
    // You could always subclass and override this if needed or do it on a background thread.
    // GCD would be great for that.
    
    [_resultsArray removeAllObjects];
    [_resultsTable reloadData];
    
    searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (searchString.length || _forcePickSearchResult){
        [_sourceArray enumerateObjectsUsingBlock:^(id sourceObject, NSUInteger idx, BOOL *stop){
            
            NSString * query = [self searchResultStringForRepresentedObject:sourceObject];
            NSString * querySubtitle = [self searchResultSubtitleForRepresentedObject:sourceObject];
            if (!querySubtitle || !_searchSubtitles) querySubtitle = @"";
            
            if ([query rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [querySubtitle rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
                (_forcePickSearchResult && searchString.length == 0)){
                
                __block BOOL shouldAdd = ![_resultsArray containsObject:sourceObject];
                if (shouldAdd && !_showAlreadyTokenized){
                    
                    [_tokenField.tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *secondStop){
                        if ([token.representedObject isEqual:sourceObject]){
                            shouldAdd = NO;
                            *secondStop = YES;
                        }
                    }];
                }
                
                if (shouldAdd) [_resultsArray addObject:sourceObject];
            }
        }];
    }
    
    if (_resultsArray.count > 0) {
        [_resultsArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[self searchResultStringForRepresentedObject:obj1] localizedCaseInsensitiveCompare:[self searchResultStringForRepresentedObject:obj2]];
        }];
        [_resultsTable reloadData];
    }
}

- (void)presentpopoverAtTokenFieldCaretAnimated:(BOOL)animated {
    
    UITextPosition * position = [_tokenField positionFromPosition:_tokenField.beginningOfDocument offset:2];
    
    [_popoverController presentPopoverFromRect:[_tokenField caretRectForPosition:position] inView:_tokenField
                      permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
}

#pragma mark Other
- (NSString *)description {
    return [NSString stringWithFormat:@"<TITokenFieldView %p; Token count = %d>", self, self.tokenTitles.count];
}

- (void)dealloc {
    [self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenField -
//==========================================================
NSString * const kTextEmpty = @"\u200B"; // Zero-Width Space
NSString * const kTextHidden = @"\u200D"; // Zero-Width Joiner

@interface TITokenFieldInternalDelegate ()
@property (nonatomic, weak) id <UITextFieldDelegate> delegate;
@property (nonatomic, weak) TITokenField * tokenField;
@end

@interface TITokenField ()
@property (nonatomic, readonly) CGFloat leftViewWidth;
@property (nonatomic, readonly) CGFloat rightViewWidth;
@property (weak, nonatomic, readonly) UIScrollView * scrollView;
@end

@interface TITokenField (Private)
- (void)setup;
- (CGFloat)layoutTokensInternal;
@end

@implementation TITokenField {
    id __weak delegate;
    TITokenFieldInternalDelegate * _internalDelegate;
    NSMutableArray * _tokens;
    CGPoint _tokenCaret;
    UILabel * _placeHolderLabel;
}
@synthesize delegate = delegate;
@synthesize editable = _editable;
@synthesize resultsModeEnabled = _resultsModeEnabled;
@synthesize removesTokensOnEndEditing = _removesTokensOnEndEditing;
@synthesize numberOfLines = _numberOfLines;
@synthesize selectedToken = _selectedToken;
@synthesize tokenizingCharacters = _tokenizingCharacters;
@synthesize forcePickSearchResult = _forcePickSearchResult;

#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])){
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])){
        [self setup];
    }
    
    return self;
}

- (void)setup {
    
    [self setBorderStyle:UITextBorderStyleNone];
    [self setFont:[UIFont fontWithName:TAG_FONT_NAME size:TOKEN_FONT_SIZE]];
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self setTintColor:[UIColor blueColor]];
    
    [self addTarget:self action:@selector(didBeginEditing) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(didEndEditing) forControlEvents:UIControlEventEditingDidEnd];
    [self addTarget:self action:@selector(didChangeText) forControlEvents:UIControlEventEditingChanged];
    
    [self.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [self.layer setShadowOpacity:0.6];
    [self.layer setShadowRadius:12];
    
    //[self setPromptText:@"To:"];
    [self setPromptText:nil];
    [self setText:kTextEmpty];
    
    _internalDelegate = [[TITokenFieldInternalDelegate alloc] init];
    [_internalDelegate setTokenField:self];
    [super setDelegate:_internalDelegate];
    
    _tokens = [NSMutableArray array];
    _editable = YES;
    _removesTokensOnEndEditing = NO;
    _tokenizingCharacters = [NSCharacterSet characterSetWithCharactersInString:@","];
}

#pragma mark Property Overrides
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:self.bounds] CGPath]];
    [self layoutTokensAnimated:NO];
}

- (void)setText:(NSString *)text {
    [super setText:(text.length == 0 ? kTextEmpty : text)];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    
    if ([self.leftView isKindOfClass:[UILabel class]]){
        [self setPromptText:((UILabel *)self.leftView).text];
    }
}

- (void)setDelegate:(id<TITokenFieldDelegate>)del {
    delegate = del;
    [_internalDelegate setDelegate:delegate];
}

- (NSArray *)tokens {
    return [_tokens copy];
}

- (NSArray *)tokenTitles {
    
    NSMutableArray * titles = [NSMutableArray array];
    [_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
        if (token.title) [titles addObject:token.title];
    }];
    return titles;
}

- (NSArray *)tokenObjects {
    
    NSMutableArray * objects = [NSMutableArray array];
    [_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
        if (token.representedObject) [objects addObject:token.representedObject];
        else if (token.title) [objects addObject:token.title];
    }];
    return objects;
}

- (UIScrollView *)scrollView {
    return ([self.superview isKindOfClass:[UIScrollView class]] ? (UIScrollView *)self.superview : nil);
}

#pragma mark Event Handling
- (BOOL)becomeFirstResponder {
    return (_editable ? [super becomeFirstResponder] : NO);
}

- (void)didBeginEditing {
    [_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[self addToken:token];}];
}

- (void)didEndEditing {
    
    [_selectedToken setSelected:NO];
    _selectedToken = nil;
    
    [self tokenizeText];
    
    if (_removesTokensOnEndEditing){
        
        [_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[token removeFromSuperview];}];
        
        NSString * untokenized = kTextEmpty;
        if (_tokens.count){
            
            NSMutableArray * titles = [NSMutableArray array];
            [_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
                if (token.title) [titles addObject:token.title];
            }];
            
            untokenized = [self.tokenTitles componentsJoinedByString:@", "];
            CGSize untokSize = [untokenized sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:TAG_FONT_NAME size:TOKEN_FONT_SIZE]}];
            //CGSize untokSize = [untokenized sizeWithFont:[UIFont fontWithName:TAG_FONT_NAME size:TOKEN_FONT_SIZE]];
            CGFloat availableWidth = self.bounds.size.width - self.leftView.bounds.size.width - self.rightView.bounds.size.width;
            
            if (_tokens.count > 1 && untokSize.width > availableWidth){
                untokenized = [NSString stringWithFormat:@"%d recipients", titles.count];
            }
            
        }
        
        [self setText:untokenized];
    }
    
    [self setResultsModeEnabled:NO];
    if (_tokens.count < 1 && self.forcePickSearchResult) {
        [self becomeFirstResponder];
    }
}

- (void)didChangeText {
    if (!self.text.length) {
        [self setText:kTextEmpty];
        [_placeHolderLabel setHidden:NO];
    } else [_placeHolderLabel setHidden:YES];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    // Stop the cut, copy, select and selectAll appearing when the field is 'empty'.
    if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(select:) || action == @selector(selectAll:))
        return ![self.text isEqualToString:kTextEmpty];
    
    return [super canPerformAction:action withSender:sender];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    if (_selectedToken && touch.view == self) [self deselectSelectedToken];
    return [super beginTrackingWithTouch:touch withEvent:event];
}

#pragma mark Token Handling
- (TIToken *)addTokenWithTitle:(NSString *)title {
    return [self addTokenWithTitle:title id:nil category:@"User" representedObject:nil];
}

- (TIToken *)addTokenWithTitle:(NSString *)title id:(NSString *)id_ category:(NSString *)category representedObject:(id)object {
    
    if (title.length){
        TIToken * token = [[TIToken alloc] initWithTitle:title id:id_ category:category representedObject:object font:self.font];
        [self addToken:token];
        return token;
    }
    
    return nil;
}

- (void)addToken:(TIToken *)token {
    
    BOOL shouldAdd = YES;
    if ([delegate respondsToSelector:@selector(tokenField:willAddToken:)]){
        shouldAdd = [delegate tokenField:self willAddToken:token];
    }
    
    if (shouldAdd){
        
        [self becomeFirstResponder];
        
        //[token addTarget:self action:@selector(tokenTouchDown:) forControlEvents:UIControlEventTouchDown];
        [token addTarget:self action:@selector(tokenTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [token addTarget:self action:@selector(tokenTouchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
        [self addSubview:token];
        
        if (![_tokens containsObject:token]) {
            [_tokens addObject:token];
            [self layoutTokensAnimated:YES];
            
            if ([delegate respondsToSelector:@selector(tokenField:didAddToken:)]){
                [delegate tokenField:self didAddToken:token];
            }
            
            [_placeHolderLabel setHidden:YES];
        }
        
        [self setResultsModeEnabled:NO];
        [self deselectSelectedToken];
    }
}

- (void)removeToken:(TIToken *)token {
    
    if (token == _selectedToken) [self deselectSelectedToken];
    
    BOOL shouldRemove = YES;
    if ([delegate respondsToSelector:@selector(tokenField:willRemoveToken:)]){
        shouldRemove = [delegate tokenField:self willRemoveToken:token];
    }
    
    if (shouldRemove) {
        
        [_tokens removeObject:token];
        [token removeFromSuperview];
        //        CGRect endRect;
        //        if (token.frame.size.width > 320) {
        //           endRect = CGRectMake(280, -20, 80, token.frame.size.height);
        //        } else {
        //            endRect = CGRectMake(token.frame.origin.x, -20, 80, token.frame.size.height);
        //        }
        //
        //        [token genieInTransitionWithDuration:0.2
        //                            destinationRect:endRect
        //                            destinationEdge:BCRectEdgeBottom
        //                                 completion:^{
        //                                     [token removeFromSuperview];
        //                                     NSLog(@"I'm done!");
        //                                 }];
        //        [UIView beginAnimations:@"suck" context:NULL];
        //        [UIView setAnimationTransition:103 forView:webView cache:NO];
        //        [UIView setAnimationDuration:1.5f];
        //        [UIView setAnimationPosition:CGPointMake(300, 1)];
        //        [UIView commitAnimations];
        //
        //        [UIView beginAnimations:@"suck" context:NULL];
        //        [UIView setAnimationTransition:103 forView:token cache:NO];
        //        [UIView setAnimationDuration:1.0];
        //        [UIView setAnimationDelegate:self];
        //        //position off screen
        //        token.frame = CGRectMake(0 - token.frame.size.width, token.frame.origin.y, token.frame.size.width, token.frame.size.height);
        //        //[UIView setAnimationDidStopSelector:@selector(finishAnimation:finished:context:)];
        //        //animate off screen
        //        [UIView commitAnimations];
        //
        //        CATransition *animation = [CATransition animation];
        //        animation.type = @"suckEffect";
        //        animation.duration = 1.0f;
        //        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        //        token.layer.opacity = 1.0f;
        //
        //        [token.layer addAnimation:animation forKey:@"transitionViewAnimation"];
        
        if (token.representedObject != nil && [token.representedObject isKindOfClass:[CustomButton class]]) {
            CustomButton *btn = (CustomButton *)token.representedObject;
            btn.enabled = YES;
            [btn setTitleColor:[UIColor colorWithHexString:@"54B5E9"] forState:UIControlStateNormal];
            btn.layer.backgroundColor = [UIColor whiteColor].CGColor;
            
            btn.layer.borderWidth = 1.5;
        }
        if ([delegate respondsToSelector:@selector(tokenField:didRemoveToken:)]){
            [delegate tokenField:self didRemoveToken:token];
        }
        
        CGFloat newWidth = [self layoutTokensInternal];
        UIScreen *mainScreen = [UIScreen mainScreen];
        if (self.bounds.size.width > mainScreen.bounds.size.width && newWidth < mainScreen.bounds.size.width) {
            newWidth = mainScreen.bounds.size.width;
        }
        if (self.bounds.size.width > mainScreen.bounds.size.width) {
            [UIView animateWithDuration:(YES ? 0.3 : 0) animations:^{
                [self setFrame:((CGRect){self.frame.origin, {newWidth, self.frame.size.height}})];
                [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
                
            } completion:^(BOOL complete){
//                if (complete) [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
            }];
        }
        [self setResultsModeEnabled:_forcePickSearchResult];
    }
}

- (void)removeAllTokens {
    
    [_tokens enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop) {
        [self removeToken:token];
    }];
    
    [self setText:@""];
}

- (void)selectToken:(TIToken *)token {
    
    [self deselectSelectedToken];
    
    _selectedToken = token;
    [_selectedToken setSelected:YES];
    
    [self becomeFirstResponder];
    [self setText:kTextHidden];
}

- (void)deselectSelectedToken {
    
    [_selectedToken setSelected:NO];
    _selectedToken = nil;
    
    [self setText:kTextEmpty];
}

- (void)tokenizeText {
    
    __block BOOL textChanged = NO;
    
    if (![self.text isEqualToString:kTextEmpty] && ![self.text isEqualToString:kTextHidden] && !_forcePickSearchResult){
        [[self.text componentsSeparatedByCharactersInSet:_tokenizingCharacters] enumerateObjectsUsingBlock:^(NSString * component, NSUInteger idx, BOOL *stop){
            [self addTokenWithTitle:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            textChanged = YES;
        }];
    }
    
    if (textChanged) [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)tokenTouchDown:(TIToken *)token {
    
    if (_selectedToken != token){
        [_selectedToken setSelected:NO];
        _selectedToken = nil;
    }
}

- (void)tokenTouchUpInside:(TIToken *)token {
    //	if (_editable) {
    //        [self selectToken:token];
    //    }
    [self removeToken:token];
}

-(void)tokenTouchDragOutside:(TIToken *)token {
    
    [self removeToken:token];
}

- (CGFloat)layoutTokensInternal {
    
    CGFloat topMargin = floor(self.font.lineHeight * 4 / 7);
    CGFloat leftMargin = self.leftViewWidth + 15;
    CGFloat hPadding = 8;
    CGFloat rightMargin = self.rightViewWidth + hPadding;
    //	CGFloat lineHeight = self.font.lineHeight + topMargin + 5;
    
    _numberOfLines = 1;
    _tokenCaret = (CGPoint){leftMargin, (topMargin - 5.5)};
    
    [_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
        
        [token setFont:self.font];
        [token setMaxWidth:(self.bounds.size.width - rightMargin - (_numberOfLines > 1 ? hPadding : leftMargin))];
        
        if (token.superview){
            
            //			if (_tokenCaret.x + token.bounds.size.width + rightMargin > self.bounds.size.width){
            //				//_numberOfLines++;
            //				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
            //				//_tokenCaret.y += lineHeight;
            //                _tokenCaret.y = lineHeight;
            //			}
            CGSize tokenSize = CGSizeMake(token.bounds.size.width, token.bounds.size.height);
            [token setFrame:(CGRect){_tokenCaret, tokenSize}];
            _tokenCaret.x += token.bounds.size.width + 4;
            
            //			if (self.bounds.size.width - _tokenCaret.x - rightMargin < 50){
            //				//_numberOfLines++;
            //				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
            //				//_tokenCaret.y += lineHeight;
            //                _tokenCaret.y = lineHeight;
            //			}
        }
    }];
    
    return _tokenCaret.x + leftMargin;
}

#pragma mark View Handlers
- (void)layoutTokensAnimated:(BOOL)animated
{
    //CGFloat newHeight = [self layoutTokensInternal];
    CGFloat newWidth = [self layoutTokensInternal];
    //UIScreen *mainScreen = [UIScreen mainScreen];
    if (newWidth > self.bounds.size.width /*|| (self.bounds.size.width > mainScreen.bounds.size.width && newWidth > mainScreen.bounds.size.width)*/) {
        
        // Animating this seems to invoke the triple-tap-delete-key-loop-problem-thing™
        [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
            [self setFrame:((CGRect){self.frame.origin, {newWidth, self.frame.size.height}})];
            [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
            
        } completion:^(BOOL complete){
//            if (complete) [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
        }];
    }
}

- (void)setResultsModeEnabled:(BOOL)flag {
    [self setResultsModeEnabled:flag animated:YES];
}

- (void)setResultsModeEnabled:(BOOL)flag animated:(BOOL)animated {
    
    [self layoutTokensAnimated:animated];
    
    if (_resultsModeEnabled != flag){
        
        //Hide / show the shadow
        [self.layer setMasksToBounds:!flag];
        
        UIScrollView * scrollView = self.scrollView;
        [scrollView setScrollsToTop:!flag];
        [scrollView setScrollEnabled:!flag];
        
        CGFloat offset = ((_numberOfLines == 1 || !flag) ? 0 : _tokenCaret.y - floor(self.font.lineHeight * 4 / 7) + 1);
        [scrollView setContentOffset:CGPointMake(0, self.frame.origin.y + offset) animated:animated];
    }
    
    _resultsModeEnabled = flag;
}

#pragma mark Left / Right view stuff

- (void)setPromptText:(NSString *)text {
    
    if (text){
        
        UILabel * label = (UILabel *)self.leftView;
        if (!label || ![label isKindOfClass:[UILabel class]]){
            label = [[UILabel alloc] initWithFrame:CGRectZero];
            [label setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
            [self setLeftView:label];
            
            [self setLeftViewMode:UITextFieldViewModeAlways];
        }
        
        [label setText:text];
        [label setFont:[UIFont systemFontOfSize:(self.font.pointSize + 1)]];
        [label sizeToFit];
    }
    else
    {
        UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"search-16"]];
        imageView.frame = CGRectMake(15, 0, 16, 16);
        [self setLeftView:imageView];
        [self setLeftViewMode:UITextFieldViewModeAlways];
    }
    
    [self layoutTokensAnimated:YES];
}

- (void)addCancelButton {
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //cancelButton.frame = CGRectMake(_tokenFieldView.frame.size.width - 60, 0, 60, 20);
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    
    [self setRightView:cancelButton];
    [self setRightViewMode:UITextFieldViewModeAlways];
    
    [self layoutTokensAnimated:YES];
}

- (void)setPlaceholder:(NSString *)placeholder {
    
    if (placeholder){
        
        UILabel * label =  _placeHolderLabel;
        if (!label || ![label isKindOfClass:[UILabel class]]){
            label = [[UILabel alloc] initWithFrame:CGRectMake(_tokenCaret.x + 3, _tokenCaret.y + 2, self.rightView.bounds.size.width, self.rightView.bounds.size.height)];
            [label setTextColor:[UIColor colorWithWhite:0.75 alpha:1]];
            _placeHolderLabel = label;
            [self addSubview: _placeHolderLabel];
        }
        
        [label setText:placeholder];
        [label setFont:[UIFont systemFontOfSize:(self.font.pointSize + 1)]];
        [label sizeToFit];
    }
    else
    {
        [_placeHolderLabel removeFromSuperview];
        _placeHolderLabel = nil;
    }
    
    [self layoutTokensAnimated:YES];
}

#pragma mark Layout
- (CGRect)textRectForBounds:(CGRect)bounds {
    
    if ([self.text isEqualToString:kTextHidden]) return CGRectMake(0, -20, 0, 0);
    
    CGRect frame = CGRectOffset(bounds, _tokenCaret.x + 2, _tokenCaret.y + 3);
    frame.size.width -= (_tokenCaret.x + self.rightViewWidth + 10);
    
    return frame;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    return ((CGRect){{8, ceilf(self.font.lineHeight * 4 / 7)}, self.leftView.bounds.size});
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
    return ((CGRect){{bounds.size.width - self.rightView.bounds.size.width - 6,
        bounds.size.height - self.rightView.bounds.size.height - 6}, self.rightView.bounds.size});
}

- (CGFloat)leftViewWidth {
    
    if (self.leftViewMode == UITextFieldViewModeNever ||
        (self.leftViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
        (self.leftViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
    
    return self.leftView.bounds.size.width;
}

- (CGFloat)rightViewWidth {
    
    if (self.rightViewMode == UITextFieldViewModeNever ||
        (self.rightViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
        (self.rightViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
    
    return self.rightView.bounds.size.width;
}

#pragma mark Other
- (NSString *)description {
    return [NSString stringWithFormat:@"<TITokenField %p; prompt = \"%@\">", self, ((UILabel *)self.leftView).text];
}

- (void)dealloc {
    [self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenFieldInternalDelegate -
//==========================================================
@implementation TITokenFieldInternalDelegate
@synthesize delegate = _delegate;
@synthesize tokenField = _tokenField;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if ([_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]){
        return [_delegate textFieldShouldBeginEditing:textField];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if ([_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]){
        [_delegate textFieldDidBeginEditing:textField];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    if ([_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]){
        return [_delegate textFieldShouldEndEditing:textField];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]){
        [_delegate textFieldDidEndEditing:textField];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (_tokenField.tokens.count && [string isEqualToString:@""] && [_tokenField.text isEqualToString:kTextEmpty]){
        [_tokenField selectToken:[_tokenField.tokens lastObject]];
        return NO;
    }
    
    if ([textField.text isEqualToString:kTextHidden]){
        [_tokenField removeToken:_tokenField.selectedToken];
        return (![string isEqualToString:@""]);
    }
    
    if ([string rangeOfCharacterFromSet:_tokenField.tokenizingCharacters].location != NSNotFound && !_tokenField.forcePickSearchResult){
        [_tokenField tokenizeText];
        return NO;
    }
    
    if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
        return [_delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //	[_tokenField tokenizeText];
    //
    //	if ([_delegate respondsToSelector:@selector(textFieldShouldReturn:)]){
    //		return [_delegate textFieldShouldReturn:textField];
    //	}
    [textField resignFirstResponder];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    if ([_delegate respondsToSelector:@selector(textFieldShouldClear:)]){
        return [_delegate textFieldShouldClear:textField];
    }
    
    [self.tokenField removeAllTokens];
    
    [textField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.05];
    
    return YES;
}

@end


//==========================================================
#pragma mark - TIToken -
//==========================================================

CGFloat const hTextPadding = 25;
CGFloat const vTextPadding = 8;
CGFloat const kDisclosureThickness = 2.5;
NSLineBreakMode const kLineBreakMode = NSLineBreakByTruncatingTail;

@interface TIToken (Private)
CGPathRef CGPathCreateTokenPath(CGSize size, BOOL innerPath);
CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width);
- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;
@end

@implementation TIToken
@synthesize title = _title;
@synthesize category = _category;
@synthesize id_ = _id_;
@synthesize representedObject = _representedObject;
@synthesize font = _font;
@synthesize tintColor = _tintColor;
@synthesize textColor = _textColor;
@synthesize highlightedTextColor = _highlightedTextColor;
@synthesize accessoryType = _accessoryType;
@synthesize maxWidth = _maxWidth;

#pragma mark Init
- (instancetype)initWithTitle:(NSString *)aTitle id:(NSString *)id_ category:(NSString *)aCategory{
    return [self initWithTitle:aTitle id:id_ category:aCategory representedObject:nil];
}

- (instancetype)initWithTitle:(NSString *)aTitle id:(NSString *)id_ category:(NSString *)aCategory representedObject:(id)object{
    return [self initWithTitle:aTitle id:id_ category:aCategory representedObject:object font:[UIFont fontWithName:TAG_FONT_NAME size:TOKEN_FONT_SIZE]];
}

- (instancetype)initWithTitle:(NSString *)aTitle id:(NSString *)id_ category:(NSString *)aCategory representedObject:(id)object font:(UIFont *)aFont {
    
    if ((self = [super init])){
        
        _title = [aTitle copy];
        _id_ = [id_ copy];
        _category = [aCategory copy];
        _representedObject = object;
        
        _font = aFont;
        _tintColor = [TIToken redTintColor];
        _textColor = [UIColor whiteColor];
        _highlightedTextColor = [UIColor whiteColor];
        
        _accessoryType = TITokenAccessoryTypeNone;
        _maxWidth = 200;
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self sizeToFit];
    }
    
    return self;
}

#pragma mark Property Overrides
- (void)setHighlighted:(BOOL)flag {
    
    if (self.highlighted != flag){
        [super setHighlighted:flag];
        [self setNeedsDisplay];
    }
}

- (void)setSelected:(BOOL)flag {
    
    if (self.selected != flag){
        [super setSelected:flag];
        [self setNeedsDisplay];
    }
}

- (void)setTitle:(NSString *)newTitle {
    
    if (newTitle){
        _title = [newTitle copy];
        [self sizeToFit];
    }
}

- (void)setFont:(UIFont *)newFont {
    
    if (!newFont) newFont = [UIFont fontWithName:TAG_FONT_NAME size:TOKEN_FONT_SIZE];
    
    if (_font != newFont){
        _font = newFont;
        [self sizeToFit];
    }
}

- (void)setTintColor:(UIColor *)newTintColor {
    
    if (!newTintColor) newTintColor = [TIToken blueTintColor];
    
    if (_tintColor != newTintColor){
        _tintColor = newTintColor;
        [self setNeedsDisplay];
    }
}

- (void)setAccessoryType:(TITokenAccessoryType)type {
    
    if (_accessoryType != type){
        _accessoryType = type;
        [self sizeToFit];
    }
}

- (void)setMaxWidth:(CGFloat)width {
    
    if (_maxWidth != width){
        _maxWidth = width;
        [self sizeToFit];
    }
}

#pragma Tint Color Convenience

+ (UIColor *)blueTintColor {
    return [UIColor colorWithRed:0.216 green:0.373 blue:0.965 alpha:1];
}

+ (UIColor *)redTintColor {
    return [UIColor colorWithRed:1 green:0.10 blue:0.10 alpha:1];
}

+ (UIColor *)orangeTintColor {
    return [UIColor colorWithRed:240.0f/255.0f green:92.0f/255.0f blue:50.0f/255.0f alpha:1];
}

+ (UIColor *)greenTintColor {
    return [UIColor colorWithRed:0.333 green:0.741 blue:0.235 alpha:1];
}

#pragma mark Layout
- (void)sizeToFit {
    
    CGFloat accessoryWidth = 0;
    
    if (_accessoryType == TITokenAccessoryTypeDisclosureIndicator){
        CGPathRelease(CGPathCreateDisclosureIndicatorPath(CGPointZero, _font.pointSize, kDisclosureThickness, &accessoryWidth));
        accessoryWidth += floorf(hTextPadding / 2);
    }
    
    CGRect frame = [_title boundingRectWithSize:CGSizeMake((_maxWidth - hTextPadding - accessoryWidth), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_font} context:nil];
    CGSize titleSize = frame.size;
    //CGSize titleSize = [_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
    CGFloat height = floorf(ceilf(titleSize.height) + vTextPadding);
    
    [self setFrame:((CGRect){self.frame.origin, {MAX(floorf(ceilf(titleSize.width) + hTextPadding + accessoryWidth), height - 3), height}})];
    [self setNeedsDisplay];
}

#pragma mark Drawing
- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw the outline.
    CGContextSaveGState(context);
    CGPathRef outlinePath = CGPathCreateTokenPath(self.bounds.size, NO);
    CGContextAddPath(context, outlinePath);
    CGPathRelease(outlinePath);
    
    BOOL drawHighlighted = (self.selected || self.highlighted);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGPoint endPoint = CGPointMake(0, self.bounds.size.height);
	   
    CGFloat red = 200.0/255.0;
    CGFloat green = 16.0/255.0;
    CGFloat blue = 26.0/255.0;
    CGFloat alpha = 1;
    //[self getTintColorRed:&red green:&green blue:&blue alpha:&alpha];
    
    if (drawHighlighted){
        CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
        CGContextFillPath(context);
    }
    else
    {
        CGContextClip(context);
        CGFloat locations[2] = {0, 0.95};
        CGFloat components[8] = {red + 0.2, green + 0.2, blue + 0.2, alpha, red, green, blue, 0.8};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 2);
        CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
        CGGradientRelease(gradient);
    }
    
    CGContextRestoreGState(context);
    
    CGPathRef innerPath = CGPathCreateTokenPath(self.bounds.size, YES);
    
    // Draw a white background so we can use alpha to lighten the inner gradient
    CGContextSaveGState(context);
    CGContextAddPath(context, innerPath);
    CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
    CGContextFillPath(context);
    CGContextRestoreGState(context);
    
    // Draw the inner gradient.
    CGContextSaveGState(context);
    CGContextAddPath(context, innerPath);
    CGPathRelease(innerPath);
    CGContextClip(context);
    
    CGFloat locations[2] = {0, (drawHighlighted ? 0.9 : 0.6)};
    //    CGFloat highlightedComp[8] = {red, green, blue, 0.7, red, green, blue, 1};
    //    CGFloat nonHighlightedComp[8] = {red, green, blue, 0.15, red, green, blue, 0.3};
    
    
    CGFloat highlightedRed = 200.0f/255.0;//1;
    CGFloat highlightedGreen = 16.0f/255.0;//0.23;
    CGFloat highlightedBlue = 26.0f/255.0;//0.18;
    
    CGFloat highlightedComp[8] = {highlightedRed, highlightedGreen, highlightedBlue, 1, highlightedRed, highlightedGreen, highlightedBlue, 1};
    CGFloat nonHighlightedComp[8] = {red, green, blue, 1, red, green, blue, 1};
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, (drawHighlighted ? highlightedComp : nonHighlightedComp), locations, 2);
    CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
    
    CGFloat accessoryWidth = 0;
    
    if (_accessoryType == TITokenAccessoryTypeDisclosureIndicator){
        CGPoint arrowPoint = CGPointMake(self.bounds.size.width - floorf(hTextPadding / 2), (self.bounds.size.height / 2) - 1);
        CGPathRef disclosurePath = CGPathCreateDisclosureIndicatorPath(arrowPoint, _font.pointSize, kDisclosureThickness, &accessoryWidth);
        accessoryWidth += floorf(hTextPadding / 2);
        
        CGContextAddPath(context, disclosurePath);
        CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
        
        if (drawHighlighted){
            CGContextFillPath(context);
        }
        else
        {
            CGContextSaveGState(context);
            CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 1, [[[UIColor whiteColor] colorWithAlphaComponent:0.6] CGColor]);
            CGContextFillPath(context);
            CGContextRestoreGState(context);
            
            CGContextSaveGState(context);
            CGContextAddPath(context, disclosurePath);
            CGContextClip(context);
            
            CGGradientRef disclosureGradient = CGGradientCreateWithColorComponents(colorspace, highlightedComp, NULL, 2);
            CGContextDrawLinearGradient(context, disclosureGradient, CGPointZero, endPoint, 0);
            CGGradientRelease(disclosureGradient);
            
            arrowPoint.y += 0.5;
            CGPathRef innerShadowPath = CGPathCreateDisclosureIndicatorPath(arrowPoint, _font.pointSize, kDisclosureThickness, NULL);
            CGContextAddPath(context, innerShadowPath);
            CGPathRelease(innerShadowPath);
            CGContextSetStrokeColor(context, (CGFloat[4]){0, 0, 0, 0.3});
            CGContextStrokePath(context);
            CGContextRestoreGState(context);
        }
        
        CGPathRelease(disclosurePath);
    }
    
    CGColorSpaceRelease(colorspace);
    
    CGRect frame = [_title boundingRectWithSize:CGSizeMake((_maxWidth - hTextPadding - accessoryWidth), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_font} context:nil];
    CGSize titleSize = frame.size;
    //CGSize titleSize = [_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
    CGFloat vPadding = floor((self.bounds.size.height - ceilf(titleSize.height)) / 2);
    CGFloat titleWidth = ceilf(self.bounds.size.width - hTextPadding - accessoryWidth);
    CGRect textBounds = CGRectMake(floorf(hTextPadding / 2), vPadding - 2, titleWidth, floorf(self.bounds.size.height - (vPadding * 2)));
    
    CGContextSetFillColorWithColor(context, (drawHighlighted ? _highlightedTextColor : _textColor).CGColor);
    [_title drawInRect:textBounds withFont:_font lineBreakMode:kLineBreakMode];
}

CGPathRef CGPathCreateTokenPath(CGSize size, BOOL innerPath) {
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat arcValue = (size.height / 2) - 1;
    CGFloat radius = arcValue - (innerPath ? (1 / [[UIScreen mainScreen] scale]) : 0);
    CGPathAddArc(path, NULL, arcValue, arcValue, radius, (M_PI / 2), (M_PI * 3 / 2), NO);
    CGPathAddArc(path, NULL, size.width - arcValue, arcValue, radius, (M_PI  * 3 / 2), (M_PI / 2), NO);
    CGPathCloseSubpath(path);
    
    return path;
}

CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width) {
    
    thickness /= cosf(M_PI / 4);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, arrowPointFront.x , arrowPointFront.y);
    
    CGPoint bottomPointFront = CGPointMake(arrowPointFront.x - (height / (2 * tanf(M_PI / 4))), arrowPointFront.y - height / 2);
    CGPathAddLineToPoint(path, NULL, bottomPointFront.x, bottomPointFront.y);
    
    CGPoint bottomPointBack = CGPointMake(bottomPointFront.x - thickness * cosf(M_PI / 4),  bottomPointFront.y + thickness * sinf(M_PI / 4));
    CGPathAddLineToPoint(path, NULL, bottomPointBack.x, bottomPointBack.y);
    
    CGPoint arrowPointBack = CGPointMake(arrowPointFront.x - thickness / cosf(M_PI / 4), arrowPointFront.y);
    CGPathAddLineToPoint(path, NULL, arrowPointBack.x, arrowPointBack.y);
    
    CGPoint topPointFront = CGPointMake(bottomPointFront.x, arrowPointFront.y + height / 2);
    CGPoint topPointBack = CGPointMake(bottomPointBack.x, topPointFront.y - thickness * sinf(M_PI / 4));
    
    //CGPathAddLineToPoint(path, NULL, topPointBack.x, topPointBack.y);
    //CGPathAddLineToPoint(path, NULL, topPointFront.x, topPointFront.y);
    CGPathAddLineToPoint(path, NULL, arrowPointFront.x, arrowPointFront.y);
    
    if (width) *width = (arrowPointFront.x - topPointBack.x);
    return path;
}

- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
    
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(_tintColor.CGColor));
    const CGFloat * components = CGColorGetComponents(_tintColor.CGColor);
    
    if (colorSpaceModel == kCGColorSpaceModelMonochrome || colorSpaceModel == kCGColorSpaceModelRGB){
        
        if (red) *red = components[0];
        if (green) *green = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[1]);
        if (blue) *blue = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[2]);
        if (alpha) *alpha = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[1] : components[3]);
        
        return YES;
    }
    
    return NO;
}

#pragma mark Other
- (NSString *)description {
    return [NSString stringWithFormat:@"<TIToken %p; title = \"%@\"; representedObject = \"%@\">", self, _title, _representedObject];
}


@end
