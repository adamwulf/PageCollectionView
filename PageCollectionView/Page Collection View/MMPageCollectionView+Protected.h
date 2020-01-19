//
//  MMPageCollectionView+Protected.h
//  PageCollectionView
//
//  Created by Adam Wulf on 1/19/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <PageCollectionView/PageCollectionView.h>

NS_ASSUME_NONNULL_BEGIN


@interface MMPageCollectionView ()

/// the transition layout that is currently in progress. After finishing or cancelling the transition, this property will return nil
/// even though the collection view technically still has the transition layout installed while it finishes its animation.
/// check this property before calling finishInteractiveTransition or cancelInteractiveTransition and only call those
/// methods if this returns non-nil
@property(nonatomic, strong, readonly) UICollectionViewTransitionLayout *activeTransitionLayout;

@end

NS_ASSUME_NONNULL_END
