//
//  MMTransitionToShelfLayout.m
//  PageCollectionView
//
//  Created by Adam Wulf on 1/22/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import "MMTransitionToShelfLayout.h"


@implementation MMTransitionToShelfLayout

- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout
{
    if (self = [super initWithCurrentLayout:currentLayout nextLayout:newLayout]) {
        // noop
    }
    return self;
}

#pragma mark - UICollectionViewLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)invalidateLayout
{
    [super invalidateLayout];
}

- (CGSize)collectionViewContentSize
{
    return [super collectionViewContentSize];
}

- (void)prepareLayout
{
    [super prepareLayout];
}

#pragma mark - Fetch Attributes

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray<__kindof UICollectionViewLayoutAttributes *> *attributes = [super layoutAttributesForElementsInRect:rect];

    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];

    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];

    return attributes;
}

@end
