//
//  ViewController.m
//  ScrollingTokenSample
//
//  Created by abhayam rastogi on 7/9/15.
//  Copyright (c) 2015 Intelligrape. All rights reserved.
//

#import "ViewController.h"
#import "TITokenField.h"
#import "UIColor+Hex.h"
#import "UIView+Genie.h"
#import "CustomButton.h"


#define TAG_TITLE_COLOR @"54B5E9"
#define TAG_BORDER_COLOR @"54B5E9"

#define LEFT_PADDING 15
#define TAG_BUTTON_HEIGHT 27
#define TAG_TITLE_PADDING 24
#define TAG_TOP_PADDING 12
#define TAG_SPACE_PADDING 9
#define TAG_BUTTON_RADIUS 14
#define TAG_BOARDER_WIDTH 1.5
#define TAG_RIGHT_PADDING 30.0f
#define TAG_MAX_WIDTH 275.f

#define TAG_FONT_NAME @"Helvetica-Light"
#define TAG_FONT_SIZE 14

@interface ViewController ()<TITokenFieldDelegate>
{
    NSArray *tagNamesArray;
}
@property (weak, nonatomic) IBOutlet UIScrollView *tagContainerScrollView;

@end

@implementation ViewController {
    TITokenFieldView *_tokenFieldView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    tagNamesArray = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z",];
    
    _tokenFieldView = [[TITokenFieldView alloc] initWithFrame:CGRectMake(0,20, 320, 80)];
    [self.view addSubview:_tokenFieldView];
    
    [_tokenFieldView setScrollEnabled:YES];
    [_tokenFieldView.tokenField setDelegate:self];
    [_tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
    [_tokenFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@",;. "]]; // Default is a comma
    [_tokenFieldView.tokenField setPromptText:nil];
    [_tokenFieldView.tokenField setPlaceholder:@"Select Genre..."];
    _tokenFieldView.tokenField.clearButtonMode = UITextFieldViewModeAlways;
    [_tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidBegin];
    [_tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidEnd];

    [_tokenFieldView setBackgroundColor:[UIColor greenColor]];
    
    [self showGenreList];
    
    [_tagContainerScrollView setBackgroundColor:[UIColor grayColor]];
}

- (void)tokenFieldFrameDidChange:(TITokenField *) tokenField {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)tokenField:(TITokenField *)tokenField willRemoveToken:(TIToken *)token {
    
    if ([token.title isEqualToString:@"Tom Irving"]){
        return NO;
    }
    
    return YES;
}

- (void)tokenFieldChangedEditing:(TITokenField *)tokenField {
    // There's some kind of annoying bug where UITextFieldViewModeWhile/UnlessEditing doesn't do anything.
//    (tokenField.editing ? UITextFieldViewModeAlways : UITextFieldViewModeNever)
   	[tokenField setRightViewMode:UITextFieldViewModeAlways];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    [_tokenFieldView.tokenField removeAllTokens];
    [textField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.05];
    
    return YES;
}

- (void)showGenreList {
    
    CGFloat height = 0.0f;
    CGFloat width = LEFT_PADDING;
    int x = LEFT_PADDING;
    int y = TAG_TOP_PADDING;
    int numberOfElementsInRow = 0;
    
    CustomButton *btn = nil;
    
    for (NSString *obj in tagNamesArray) {
        NSString *title = obj;
        
        CGRect frame = [title boundingRectWithSize:CGSizeMake(TAG_MAX_WIDTH, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont fontWithName:TAG_FONT_NAME size:TAG_FONT_SIZE]} context:nil];
        
        CGSize size = frame.size;
        height += size.height;
        width += (size.width + TAG_TITLE_PADDING + TAG_SPACE_PADDING);
        numberOfElementsInRow++;
        
        if (width >= self.view.frame.size.width - TAG_RIGHT_PADDING) {
            numberOfElementsInRow = 0;
            width = (LEFT_PADDING + size.width + TAG_TITLE_PADDING + TAG_SPACE_PADDING);
            x = LEFT_PADDING;
            y += TAG_BUTTON_HEIGHT + TAG_TOP_PADDING;
        }
        
        [self addButton:&btn size:size y:y x_p:&x title:title];
        [_tagContainerScrollView setContentSize:CGSizeMake(_tagContainerScrollView.frame.size.width, CGRectGetMaxY(btn.frame) + 20)];
    }
}

- (void)addButton:(UIButton **)btn_p size:(CGSize)size y:(int)y x_p:(int *)x_p title:(NSString *)title {
    *btn_p = [CustomButton buttonWithType:UIButtonTypeCustom];
    (*btn_p).frame = CGRectMake(*x_p, y, size.width + TAG_TITLE_PADDING, TAG_BUTTON_HEIGHT);
    [*btn_p setTitle:title forState:UIControlStateNormal];
    (*btn_p).titleLabel.font = [UIFont fontWithName:TAG_FONT_NAME size:TAG_FONT_SIZE];
    [*btn_p setTitleColor:[UIColor colorWithHexString:TAG_TITLE_COLOR] forState:UIControlStateNormal] ;
    [*btn_p addTarget:self action:@selector(tagTapped:) forControlEvents:UIControlEventTouchUpInside];
    (*btn_p).layer.cornerRadius = TAG_BUTTON_RADIUS;
    (*btn_p).layer.borderColor = [UIColor colorWithHexString:TAG_BORDER_COLOR].CGColor;
    (*btn_p).layer.borderWidth = TAG_BOARDER_WIDTH;
    (*btn_p).contentEdgeInsets = UIEdgeInsetsMake(5, 0, 0, 0);
    [_tagContainerScrollView addSubview:*btn_p];
    *x_p += (size.width + TAG_TITLE_PADDING + TAG_SPACE_PADDING);
}

-(void)tagTapped:(CustomButton *)buttonRef {
    
    buttonRef.enabled = NO;
    buttonRef.layer.backgroundColor = [UIColor colorWithHexString:TAG_BORDER_COLOR].CGColor;
    buttonRef.layer.borderWidth = 0.0;
    [buttonRef setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_tokenFieldView.tokenField addTokenWithTitle:buttonRef.titleLabel.text id:buttonRef.buttonId category:buttonRef.category representedObject:buttonRef];
    [_tokenFieldView.tokenField resignFirstResponder];
}

@end
