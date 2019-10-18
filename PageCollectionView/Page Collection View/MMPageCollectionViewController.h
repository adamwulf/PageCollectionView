//
//  MMPageCollectionViewController.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/5/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMPageLayout.h"

@class MMPageLayout, MMGridLayout;

NS_ASSUME_NONNULL_BEGIN

@interface MMPageCollectionViewController : UICollectionViewController <MMPageCollectionViewDelegatePageLayout>

/// Returns the current layout of the collection view. If the collectionview is in the middel of a transition layout,
/// then the current layout of that transition layout is returned
- (__kindof MMShelfLayout*)currentLayout;

#pragma mark - Subclasses

@property (nonatomic, readonly) CGFloat scale;

-(MMShelfLayout*)newShelfLayout;
-(MMGridLayout*)newGridLayoutForSection:(NSUInteger)section;
-(MMPageLayout*)newPageLayoutForSection:(NSUInteger)section;

-(void)willBeginZoom;
-(void)didEndZoom;
-(void)didCancelZoom;

@end

NS_ASSUME_NONNULL_END
