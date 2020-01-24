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
@property(nonatomic, readonly) CGPoint scaledAdjustment;
@property(nonatomic, readonly) CGPoint adjustment;

- (CGPoint)scaledFirstLocationInView:(UIView *)view;
- (CGPoint)firstLocationInView:(UIView *)view;
- (CGPoint)oldLocationInView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
