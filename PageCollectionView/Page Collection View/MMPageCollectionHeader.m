//
//  MMPageCollectionHeader.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageCollectionHeader.h"


@interface MMPageCollectionHeader ()

@property(nonatomic, strong) UILabel *lbl;

@end


@implementation MMPageCollectionHeader

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
    _lbl = [[UILabel alloc] initWithFrame:[self bounds]];
    [_lbl setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_lbl setTextAlignment:NSTextAlignmentCenter];

    [[_lbl layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[_lbl layer] setBorderWidth:1];

    [self addSubview:_lbl];
    [self setBackgroundColor:[UIColor whiteColor]];
}

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    [_lbl setText:[NSString stringWithFormat:@"Book %@, %@", @(indexPath.section), @(indexPath.row)]];
}

@end
