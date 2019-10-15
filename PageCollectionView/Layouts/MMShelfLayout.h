//
//  MMShelfLayout.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMPageCollectionView.h"
#import "MMShelfLayoutObject.h"

NS_ASSUME_NONNULL_BEGIN

@class MMShelfLayout;

/// Similar  to UICollectionViewDelegateFlowLayout, these delegate method will be used by the layout
/// for item specific properties. If they are not implemented, then defaultHeaderSize or defaultItemSize
/// will be used instead.
@protocol MMPageCollectionViewDataSourceShelfLayout <UICollectionViewDataSource>

- (id<MMShelfLayoutObject>)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout objectAtIndexPath:(NSIndexPath *)indexPath;

@end

/// Similar  to UICollectionViewDelegateFlowLayout, these delegate method will be used by the layout
/// for item specific properties. If they are not implemented, then defaultHeaderSize or defaultItemSize
/// will be used instead.
@protocol MMPageCollectionViewDelegateShelfLayout <MMPageCollectionViewDelegate>
@optional

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;

@end


@interface MMShelfLayout : UICollectionViewLayout

@property(nonatomic, assign) CGSize defaultHeaderSize;
@property(nonatomic, assign) CGFloat maxDim;

@property(nonatomic, assign) UIEdgeInsets sectionInsets;
@property(nonatomic, assign) NSUInteger pageSpacing;

@property(nonatomic, strong, nullable) NSIndexPath *targetIndexPath;
@property(nonatomic, readonly) id<MMPageCollectionViewDelegateShelfLayout> delegate;
@property(nonatomic, readonly) id<MMPageCollectionViewDataSourceShelfLayout> datasource;

@property(nonatomic, readonly) BOOL isShelfLayout;
@property(nonatomic, readonly) BOOL isGridLayout;
@property(nonatomic, readonly) BOOL isPageLayout;

@end

NS_ASSUME_NONNULL_END
