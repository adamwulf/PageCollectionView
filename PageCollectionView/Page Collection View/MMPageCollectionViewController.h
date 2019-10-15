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

- (MMPageLayout *)isPageLayout;
- (MMShelfLayout *)isShelfLayout;
- (MMGridLayout *)isGridLayout;

@end

NS_ASSUME_NONNULL_END
