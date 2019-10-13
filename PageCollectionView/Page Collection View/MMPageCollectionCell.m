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

- (instancetype)init
{
    if (self = [super init]) {
        [self finishInit];
    }
    return self;
}

- (void)finishInit
{
    _textLabel = [[UILabel alloc] initWithFrame:[self bounds]];
    [_textLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
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
}

@end
