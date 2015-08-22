//
//  UIColor+Hex.h
//  Search
//
//  Created by shiva on 9/2/13.
//  Copyright (c) 2013 Apalya Technlologies Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface UIColor (Hex)

+(UIColor *)colorWithHexString:(NSString *)stringToConvert;
+(UIColor *)getPlaceHolderColor;

@end
