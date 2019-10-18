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

@protocol MMPageCollectionViewDelegatePageLayout <MMPageCollectionViewDelegateShelfLayout>
@optional

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(MMPageLayout *)collectionViewLayout zoomScaleForIndexPath:(NSIndexPath*)indexPath;

@end

@interface MMPageLayout : MMGridLayout

@property(nonatomic, readonly) id<MMPageCollectionViewDelegatePageLayout> delegate;

@end

NS_ASSUME_NONNULL_END
