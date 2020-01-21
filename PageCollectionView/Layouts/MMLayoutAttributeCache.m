//
//  MMLayoutAttributeCache.m
//  PageCollectionView
//
//  Created by Adam Wulf on 1/21/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import "MMLayoutAttributeCache.h"


@interface MMLayoutAttributeCache ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *visibleItems;
@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *hiddenItems;

@end


@implementation MMLayoutAttributeCache

+ (instancetype)cacheWithAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    MMLayoutAttributeCache *cache = [[MMLayoutAttributeCache alloc] init];

    [cache appendLayoutAttributes:attributes];

    return cache;
}

- (instancetype)init
{
    if (self = [super init]) {
        _visibleItems = [NSMutableArray array];
        _hiddenItems = [NSMutableArray array];
        _frame = CGRectNull;
    }
    return self;
}

- (void)appendLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    _frame = CGRectUnion(_frame, [attributes frame]);

    if ([attributes isHidden]) {
        [_hiddenItems addObject:attributes];
    } else {
        [_visibleItems addObject:attributes];
    }
}

- (NSArray<UICollectionViewLayoutAttributes *> *)allItems
{
    return [_visibleItems arrayByAddingObjectsFromArray:_hiddenItems];
}

@end
