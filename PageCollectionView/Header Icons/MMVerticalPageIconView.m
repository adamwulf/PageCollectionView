//
//  MMVerticalPageIconView.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/7/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMVerticalPageIconView.h"

#define interpolate(s, e, p) (s * p + e * (1 - p))


@implementation MMVerticalPageIconView

- (instancetype)init
{
    if (self = [super init]) {
        [self finishInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self finishInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self finishInit];
    }
    return self;
}

- (void)finishInit
{
    NSInteger const cols = 4;
    NSInteger const rows = 4;
    NSInteger zIndex = rows * cols;

    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < cols; col++) {
            UIView *page = [[UIView alloc] initWithFrame:CGRectZero];

            [[page layer] setBackgroundColor:[[UIColor whiteColor] CGColor]];
            [[page layer] setBorderColor:[[UIColor blackColor] CGColor]];
            [[page layer] setBorderWidth:1];
            [[page layer] setZPosition:zIndex];

            [self addSubview:page];
            zIndex -= 1;
        }
    }

    [self setNeedsLayout];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    NSInteger const cols = 4;
    NSInteger const rows = 2;
    CGFloat const margin = 4;
    CGFloat myWidth = CGRectGetWidth([self bounds]);
    CGFloat myHeight = CGRectGetHeight([self bounds]);
    CGFloat pageHeight = myHeight / rows;
    CGFloat pageWidth = myWidth / cols;
    CGFloat gridXStep = pageWidth;
    CGFloat gridYStep = pageHeight;
    CGFloat yOffset = pageHeight * (rows * cols) - myHeight;

    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < cols; col++) {
            CGRect pageFrame = CGRectMake((myWidth - pageWidth) / 2.0, pageHeight * (row * cols + col) - yOffset, pageWidth, pageHeight);
            pageFrame = CGRectInset(pageFrame, margin, margin);

            CGRect gridFrame = CGRectMake(gridXStep * col, gridYStep * row, pageWidth, pageHeight);
            gridFrame = CGRectInset(gridFrame, margin, margin);

            UIView *page = [[self subviews] objectAtIndex:(row * cols + col)];

            CGRect final = CGRectMake(interpolate(CGRectGetMinX(gridFrame), CGRectGetMinX(pageFrame), _progress), interpolate(CGRectGetMinY(gridFrame), CGRectGetMinY(pageFrame), _progress), CGRectGetWidth(pageFrame), CGRectGetHeight(pageFrame));

            [page setFrame:final];
        }
    }

    [super layoutSubviews];
}

@end
