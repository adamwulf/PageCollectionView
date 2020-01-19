//
//  MMPageCollectionViewController+Protected.h
//  PageCollectionView
//
//  Created by Adam Wulf on 1/18/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <PageCollectionView/PageCollectionView.h>

NS_ASSUME_NONNULL_BEGIN


@interface MMPageCollectionViewController (Protected)

@property(nonatomic, readonly) CGFloat maxPageScale;
@property(nonatomic, readonly) CGFloat pageScale;

#pragma mark - MMPageCollectionViewDelegatePageLayout

- (void)collectionView:(UICollectionView *)collectionView willChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout NS_REQUIRES_SUPER;

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout NS_REQUIRES_SUPER;

#pragma mark - Layout Helpers

- (BOOL)isDisplayingShelf;
- (BOOL)isDisplayingGrid;
- (BOOL)isDisplayingPage;

#pragma mark - Subclasses

- (MMShelfLayout *)newShelfLayout;
- (MMGridLayout *)newGridLayoutForSection:(NSUInteger)section;
- (MMPageLayout *)newPageLayoutForSection:(NSUInteger)section;

@end

NS_ASSUME_NONNULL_END
