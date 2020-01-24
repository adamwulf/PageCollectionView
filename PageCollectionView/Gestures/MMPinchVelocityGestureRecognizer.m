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
    NSMutableSet<UITouch *> *_touches;

    CGPoint _adjustWait;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _touches = [[NSMutableSet alloc] init];
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    if (self = [super initWithTarget:target action:action]) {
        _touches = [[NSMutableSet alloc] init];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        _touches = [[NSMutableSet alloc] init];
    }
    return self;
}

- (CGPoint)oldLocationInView:(UIView *)view
{
    return [super locationInView:view];
}

- (CGPoint)firstLocationInView:(UIView *)view
{
    CGPoint loc = CGPointZero;

    for (UITouch *touch in _touches) {
        CGPoint touchLoc = [touch locationInView:view];

        loc.x += touchLoc.x;
        loc.y += touchLoc.y;
    }

    if ([_touches count]) {
        loc.x /= [_touches count];
        loc.y /= [_touches count];
    }

    loc.x += _adjustment.x * [self scale];
    loc.y += _adjustment.y * [self scale];

    loc.x += _adjustWait.x;
    loc.y += _adjustWait.y;

    return loc;
}

- (CGPoint)locationInView:(UIView *)view
{
    CGPoint loc = [self firstLocationInView:view];

    loc.x -= _adjustment.x * [self scale];
    loc.y -= _adjustment.y * [self scale];

    return loc;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UIGestureRecognizerState stateBefore = [self state];
    CGPoint before = [self locationInView:[self view]];
    [_touches addObjectsFromArray:[touches allObjects]];

    [super touchesBegan:touches withEvent:event];
    CGPoint after = [self locationInView:[self view]];

    if ([_touches count] > 1 && stateBefore == UIGestureRecognizerStateChanged) {
        _adjustment.x += _adjustWait.x / [self scale];
        _adjustment.y += _adjustWait.y / [self scale];
        _adjustment.x += (before.x - after.x) / [self scale];
        _adjustment.y += (before.y - after.y) / [self scale];

        _adjustWait = CGPointZero;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _lastScale = [self scale];

    [super touchesMoved:touches withEvent:event];

    CGFloat updatedDirection = [self scale] - _lastScale;

    _scaleDirection = _scaleDirection * kLowPass + updatedDirection * (1.0 - _scaleDirection);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint before = [self locationInView:[self view]];

    for (UITouch *touch in [touches allObjects]) {
        [_touches removeObject:touch];
    }

    [super touchesEnded:touches withEvent:event];

    CGPoint after = [self locationInView:[self view]];

    _adjustWait.x += (before.x - after.x);
    _adjustWait.y += (before.y - after.y);

    if ([_touches count] <= 0) {
        _adjustment = CGPointZero;
        _adjustWait = CGPointZero;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in [touches allObjects]) {
        [_touches removeObject:touch];
    }
    [super touchesCancelled:touches withEvent:event];

    if ([_touches count] == 0) {
        _adjustment = CGPointZero;
        _adjustWait = CGPointZero;
    }
}

- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event
{
    CGPoint before = [self locationInView:[self view]];

    [_touches removeObject:touch];

    [super ignoreTouch:touch forEvent:event];

    CGPoint after = [self locationInView:[self view]];

    _adjustWait.x -= (before.x - after.x);
    _adjustWait.y -= (before.y - after.y);

    if ([_touches count] == 0) {
        _adjustment = CGPointZero;
        _adjustWait = CGPointZero;
    }
}

@end
