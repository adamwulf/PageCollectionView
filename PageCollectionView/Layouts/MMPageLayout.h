//
//  MMPageLayout.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMGridLayout.h"

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

@end

NS_ASSUME_NONNULL_END
