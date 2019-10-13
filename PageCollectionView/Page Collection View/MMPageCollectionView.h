//
//  MMPageCollectionView.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/7/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMPageCollectionViewDelegate <UICollectionViewDelegate>
@optional

- (void)collectionView:(UICollectionView *)collectionView willChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout;

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout;

@end


@interface MMPageCollectionView : UICollectionView

@property(nonatomic, weak) id<MMPageCollectionViewDelegate> delegate;

- (NSIndexPath *)closestIndexPathForPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
