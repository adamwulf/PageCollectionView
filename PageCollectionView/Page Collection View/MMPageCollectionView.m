//
//  MMPageCollectionView.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/7/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageCollectionView.h"

/// useful when comparing to another squared distance
#define sqDist(p1, p2) ((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y))


@implementation MMPageCollectionView
@dynamic delegate;

#pragma mark - Layout Helpers

- (UICollectionViewTransitionLayout *)activeTransitionLayout
{
    return [[self collectionViewLayout] isKindOfClass:[UICollectionViewTransitionLayout class]] ? (UICollectionViewTransitionLayout *)[self collectionViewLayout] : nil;
}

- (__kindof MMShelfLayout *)currentLayout
{
    return (MMShelfLayout *)([self activeTransitionLayout] ? [[self activeTransitionLayout] currentLayout] : [self collectionViewLayout]);
}

#pragma mark - UICollectionView

- (void)setCollectionViewLayout:(UICollectionViewLayout *)layout
{
    UICollectionViewLayout *previousLayout = [self collectionViewLayout];

    if ([[self delegate] respondsToSelector:@selector(collectionView:willChangeToLayout:fromLayout:)]) {
        [[self delegate] collectionView:self willChangeToLayout:layout fromLayout:previousLayout];
    }

    [super setCollectionViewLayout:layout];

    if ([[self delegate] respondsToSelector:@selector(collectionView:didChangeToLayout:fromLayout:)]) {
        [[self delegate] collectionView:self didChangeToLayout:layout fromLayout:previousLayout];
    }
}

- (void)setCollectionViewLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated
{
    __weak id weakSelf = self;
    UICollectionViewLayout *previousLayout = [self collectionViewLayout];

    if ([[self delegate] respondsToSelector:@selector(collectionView:willChangeToLayout:fromLayout:)]) {
        [[self delegate] collectionView:self willChangeToLayout:layout fromLayout:previousLayout];
    }

    [super setCollectionViewLayout:layout animated:animated completion:^(BOOL finished) {
        if (animated && finished && [[self delegate] respondsToSelector:@selector(collectionView:didChangeToLayout:fromLayout:)]) {
            [[weakSelf delegate] collectionView:weakSelf didChangeToLayout:layout fromLayout:previousLayout];
        }
    }];

    if (!animated && [[self delegate] respondsToSelector:@selector(collectionView:didChangeToLayout:fromLayout:)]) {
        [[self delegate] collectionView:self didChangeToLayout:layout fromLayout:previousLayout];
    }
}

- (void)setCollectionViewLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    __weak id weakSelf = self;
    UICollectionViewLayout *previousLayout = [self collectionViewLayout];

    if ([[self delegate] respondsToSelector:@selector(collectionView:willChangeToLayout:fromLayout:)]) {
        [[self delegate] collectionView:self willChangeToLayout:layout fromLayout:previousLayout];
    }

    [super setCollectionViewLayout:layout animated:animated completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }

        if (animated && finished && [[self delegate] respondsToSelector:@selector(collectionView:didChangeToLayout:fromLayout:)]) {
            [[weakSelf delegate] collectionView:weakSelf didChangeToLayout:layout fromLayout:previousLayout];
        }
    }];

    if (!animated && [[self delegate] respondsToSelector:@selector(collectionView:didChangeToLayout:fromLayout:)]) {
        [[self delegate] collectionView:self didChangeToLayout:layout fromLayout:previousLayout];
    }
}

- (void)cancelInteractiveTransition
{
    [super cancelInteractiveTransition];

    if ([[self delegate] respondsToSelector:@selector(collectionView:didFinalizeTransitionLayout:)]) {
        [[self delegate] collectionView:self didFinalizeTransitionLayout:[self activeTransitionLayout]];
    }
}

- (void)finishInteractiveTransition
{
    [super finishInteractiveTransition];

    if ([[self delegate] respondsToSelector:@selector(collectionView:didFinalizeTransitionLayout:)]) {
        [[self delegate] collectionView:self didFinalizeTransitionLayout:[self activeTransitionLayout]];
    }
}

#pragma mark - Public API

- (NSIndexPath *)closestIndexPathForPoint:(CGPoint)point
{
    UICollectionViewCell *closest = nil;

    for (UICollectionViewCell *cell in [self visibleCells]) {
        if ([cell pointInside:[self convertPoint:point toView:cell] withEvent:nil]) {
            return [self indexPathForCell:cell];
        }

        if (!closest) {
            closest = cell;
        } else {
            CGFloat dist1 = sqDist([closest center], point);
            CGFloat dist2 = sqDist([cell center], point);

            if (dist2 < dist1) {
                closest = cell;
            }
        }
    }

    return closest ? [self indexPathForCell:closest] : nil;
}

@end
