//
//  MMPinchVelocityGestureRecognizer.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface MMPinchVelocityGestureRecognizer : UIPinchGestureRecognizer

@property(nonatomic, readonly) CGFloat scaleDirection;
/// Adjustment tracks the distance that UIKit thinks the gesture has moved, vs what we'll output in our location
@property(nonatomic, readonly) CGPoint adjustment;
/// scaledAdjustment tracks the adjustment location, but multiplies each step by the current scale. useful for
/// tracking adjustment with scaling content
@property(nonatomic, readonly) CGPoint scaledAdjustment;

- (CGPoint)scaledFirstLocationInView:(UIView *)view;
- (CGPoint)firstLocationInView:(UIView *)view;
- (CGPoint)oldLocationInView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
