//
//  MMShelfLayout.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMPageCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@class MMShelfLayout;

/// Similar  to UICollectionViewDelegateFlowLayout, these delegate method will be used by the layout
/// for item specific properties. If they are not implemented, then defaultHeaderSize or defaultItemSize
/// will be used instead.
@protocol MMPageCollectionViewDelegateShelfLayout <MMPageCollectionViewDelegate>
@optional

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface MMShelfLayout : UICollectionViewLayout

@property(nonatomic, assign) CGSize defaultHeaderSize;
@property(nonatomic, assign) CGSize defaultItemSize;

@property(nonatomic, assign) UIEdgeInsets sectionInsets;
@property(nonatomic, assign) NSUInteger pageSpacing;

@property(nonatomic, strong, nullable) NSIndexPath *targetIndexPath;
@property(nonatomic, readonly) id<MMPageCollectionViewDelegateShelfLayout> delegate;

@end

NS_ASSUME_NONNULL_END
