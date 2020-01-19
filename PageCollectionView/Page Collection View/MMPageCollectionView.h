//
//  MMPageCollectionView.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/7/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MMShelfLayout;

@protocol MMPageCollectionViewDelegate <UICollectionViewDelegate>
@optional

- (void)collectionView:(UICollectionView *)collectionView willChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout;

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout;

- (void)collectionView:(UICollectionView *)collectionView didFinalizeTransitionLayout:(UICollectionViewTransitionLayout *)transitionLayout;

@end


@interface MMPageCollectionView : UICollectionView

@property(nonatomic, weak) id<MMPageCollectionViewDelegate> delegate;

- (NSIndexPath *)closestIndexPathForPoint:(CGPoint)point;

/// Returns the current layout of the collection view. If the collectionview is in the middel of a transition layout,
/// then the current layout of that transition layout is returned
- (__kindof MMShelfLayout *)currentLayout;
- (nullable UICollectionViewTransitionLayout *)activeTransitionLayout;

@end

NS_ASSUME_NONNULL_END
