//
//  UIColor+Hex.m
//  Search
//
//  Created by shiva on 9/2/13.
//  Copyright (c) 2013 Apalya Technlologies Pvt. Ltd. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *) colorWithHexString: (NSString *) stringToConvert {
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor blackColor];
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString length] != 6) return [UIColor blackColor];
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

+(UIColor *)getPlaceHolderColor {
    
    NSDictionary *colorCodesDict = @{@"one": @"93c8ce",@"two": @"55c476",@"three": @"badb42",@"four": @"f2d351",@"five": @"f78777"};
    
    NSArray* allKeys = [colorCodesDict allKeys];
    id randomKey = allKeys[arc4random_uniform([allKeys count])];
    id randomObject = colorCodesDict[randomKey];
    return  [UIColor colorWithHexString:randomObject];
}

@end

