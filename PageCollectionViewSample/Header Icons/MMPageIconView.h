//
//  MMPageIconView.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/7/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface MMPageIconView : UIView

/// between 0 and 1. 0 will show page view, 1 will show grid row
@property(nonatomic, assign) CGFloat progress;

@end

NS_ASSUME_NONNULL_END
