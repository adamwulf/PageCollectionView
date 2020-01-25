//
//  MMHorizontalPageIconView.h
//  PageCollectionView
//
//  Created by Adam Wulf on 1/24/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface MMHorizontalPageIconView : UIView

/// between 0 and 1. 0 will show page view, 1 will show grid row
@property(nonatomic, assign) CGFloat progress;

@end

NS_ASSUME_NONNULL_END
