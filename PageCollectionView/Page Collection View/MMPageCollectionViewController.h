//
//  MMPageCollectionViewController.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/5/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMShelfLayout.h"

@class MMPageLayout, MMGridLayout;

NS_ASSUME_NONNULL_BEGIN

@interface MMPageCollectionViewController : UICollectionViewController <MMPageCollectionViewDelegateShelfLayout>

/// Returns the current layout of the collection view. If the collectionview is in the middel of a transition layout,
/// then the current layout of that transition layout is returned
- (__kindof MMShelfLayout*)currentLayout;

#pragma mark - Subclasses

-(MMShelfLayout*)newShelfLayout;
-(MMGridLayout*)newGridLayoutForSection:(NSUInteger)section;
-(MMPageLayout*)newPageLayoutForSection:(NSUInteger)section;

@end

NS_ASSUME_NONNULL_END
