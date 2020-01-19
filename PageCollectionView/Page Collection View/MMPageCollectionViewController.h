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


@interface MMPageCollectionViewController : UIViewController <UICollectionViewDataSource, MMPageCollectionViewDelegatePageLayout> {
    CGFloat _pageScale;
}

@property(nonatomic, strong, readonly) MMPageCollectionView *collectionView;

@end

NS_ASSUME_NONNULL_END
