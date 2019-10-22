//
//  MMPageCollectionCell.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/5/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageCollectionCell.h"


@interface MMPageCollectionCell ()

@end


@implementation MMPageCollectionCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self _completePageCollectionCellInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self _completePageCollectionCellInit];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self _completePageCollectionCellInit];
    }
    return self;
}

- (void)_completePageCollectionCellInit
{
    _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
    [_textLabel setAutoresizingMask:UIViewAutoresizingNone];
    [_textLabel setTextAlignment:NSTextAlignmentCenter];
    [_textLabel setFont:[UIFont systemFontOfSize:22]];

    [[self layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[self layer] setBorderWidth:1];

    [self addSubview:_textLabel];
    [self setBackgroundColor:[UIColor whiteColor]];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];

    // UIKit bug, apply zPosition manually
    // https://stackoverflow.com/questions/31697578/uicollectionview-not-obeying-zindex-of-uicollectionviewlayoutattributes
    [[self layer] setZPosition:[layoutAttributes zIndex]];
    [self updateTextLabelTransform];
}

#pragma mark - Frame and Bounds

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self updateTextLabelTransform];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self updateTextLabelTransform];
}

-(void)updateTextLabelTransform{
    CGFloat scale = CGRectGetWidth([self bounds]) / CGRectGetWidth([[self textLabel] bounds]);
    
    [[self textLabel] setCenter:CGPointMake(CGRectGetMidX([self bounds]), CGRectGetMidY([self bounds]))];
    [[self textLabel] setTransform:CGAffineTransformMakeScale(scale, scale)];
}

@end
