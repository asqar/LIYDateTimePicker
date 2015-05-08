//
// Created by Liron Yahdav on 5/8/15.
// Copyright (c) 2015 Liron Yahdav. All rights reserved.
//

#import "UIView+LIYSpecAdditions.h"

@implementation UIView (LIYSpecAdditions)

- (UILabel *)liy_specsFindLabelWithText:(NSString *)text {
    NSPredicate *labelPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([evaluatedObject isKindOfClass:[UILabel class]]) {
            if ([[evaluatedObject text] isEqualToString:text]) {
                return YES;
            }
        }
        return NO;
    }];

    return (UILabel *)[self liy_traverseDescendantsWithPredicate:labelPredicate];
}

#pragma mark - convenience

- (UIView *)liy_traverseDescendantsWithPredicate:(NSPredicate *)predicate {
    if ([predicate evaluateWithObject:self]) {
        return self;
    }

    // check subviews
    for (UIView *subview in [self subviews]) {
        UIView *result = [subview liy_traverseDescendantsWithPredicate:predicate];
        if (result) {
            return result;
        }
    }

    return nil;
}

@end
