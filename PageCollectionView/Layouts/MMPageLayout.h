//
//  MMPageLayout.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMGridLayout.h"
#import "MMPinchVelocityGestureRecognizer.h"

NS_ASSUME_NONNULL_BEGIN

@class MMPageLayout;

typedef enum : NSUInteger {
    MMPageLayoutHorizontal = 0,
    MMPageLayoutVertical,
} MMPageLayoutDirection;

@protocol MMPageCollectionViewDelegatePageLayout <MMPageCollectionViewDelegateShelfLayout>
@optional

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(MMPageLayout *)collectionViewLayout zoomScaleForIndexPath:(NSIndexPath *)indexPath;

@end


@interface MMPageLayout : MMGridLayout

@property(nonatomic, readonly) id<MMPageCollectionViewDelegatePageLayout> delegate;

/// When YES, all pages will scale to fit width of collection view.
/// When NO, pages will only scale to fit width when already too large. Small pages will stay small.
@property(nonatomic, assign) BOOL fitWidth;
@property(nonatomic, assign) MMPageLayoutDirection direction;
/// The percent (from 0 to 1) of the target offset for the layout. This is used for the pinch gesture to keep
/// the same location in the page centered under the gesture.
@property(nonatomic, assign) CGPoint startingPercentOffset;
@property(nonatomic, assign, nullable) MMPinchVelocityGestureRecognizer *gestureRecognizer;

@end

NS_ASSUME_NONNULL_END
