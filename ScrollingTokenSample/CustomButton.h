//
//  CustomButton.h
//  APTV_3_0
//
//  Created by Manikanta on 13/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomButton : UIButton {

	NSString *buttonId;
    NSUInteger custumbtnid;
    NSString *category;
    NSIndexPath *indexPath;
}

@property (nonatomic, strong) NSString *category;
@property (nonatomic,readwrite) NSUInteger custumbtnid;
@property (nonatomic,strong) NSString *buttonId;
@property (nonatomic,strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSString *cotentId;

@end
