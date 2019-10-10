//
//  MMPinchVelocityGestureRecognizer.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPinchVelocityGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

CGFloat const kLowPass = .8;


@implementation MMPinchVelocityGestureRecognizer {
    CGFloat _lastScale;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _lastScale = [self scale];

    [super touchesMoved:touches withEvent:event];

    CGFloat updatedDirection = [self scale] - _lastScale;

    _scaleDirection = _scaleDirection * kLowPass + updatedDirection * (1.0 - _scaleDirection);
}

@end
