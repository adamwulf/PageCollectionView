//
//  MMPageCollectionViewController.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/5/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageCollectionViewController.h"
#import "MMPinchVelocityGestureRecognizer.h"
#import "MMPageCollectionView.h"
#import "MMPageCollectionCell.h"
#import "MMPageCollectionHeader.h"
#import "MMGridIconView.h"
#import "MMPageIconView.h"
#import "MMShelfLayout.h"
#import "MMGridLayout.h"
#import "MMPageLayout.h"


@interface MMPageCollectionViewController () <MMPageCollectionViewDelegate>

@property(nonatomic, strong) UICollectionViewFlowLayout *pageLayout;
@property(nonatomic, assign) BOOL transitionComplete;

@end


@implementation MMPageCollectionViewController {
    NSIndexPath *_targetIndexPath;
    MMGridIconView *_collapseGridIcon;
    MMPageIconView *_collapsePageIcon;
    
    CGPoint _zoomOffset;
    NSNumber *_isZoomingPage;
    MMPinchVelocityGestureRecognizer *_pinchGesture;
}

@synthesize scale = _scale;

+ (UICollectionViewLayout *)layout
{
    return [[MMShelfLayout alloc] init];
}

- (instancetype)init
{
    if (self = [super initWithCollectionViewLayout:[[self class] layout]]) {
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView setBackgroundColor:[UIColor lightGrayColor]];
    [self.collectionView registerClass:[MMPageCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass([MMPageCollectionCell class])];
    [self.collectionView registerClass:[MMPageCollectionHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([MMPageCollectionHeader class])];
    [self.collectionView reloadData];

    _pinchGesture = [[MMPinchVelocityGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [[self collectionView] addGestureRecognizer:_pinchGesture];

    _collapseGridIcon = [[MMGridIconView alloc] initWithFrame:CGRectZero];
    [_collapseGridIcon setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self collectionView] addSubview:_collapseGridIcon];

    [[[_collapseGridIcon centerXAnchor] constraintEqualToAnchor:[[self collectionView] centerXAnchor]] setActive:YES];
    [[[_collapseGridIcon widthAnchor] constraintEqualToConstant:100] setActive:YES];
    [[[_collapseGridIcon heightAnchor] constraintEqualToConstant:60] setActive:YES];
    [[[_collapseGridIcon bottomAnchor] constraintEqualToAnchor:[[self collectionView] topAnchor] constant:-25] setActive:YES];

    _collapsePageIcon = [[MMPageIconView alloc] initWithFrame:CGRectZero];
    [_collapsePageIcon setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self collectionView] addSubview:_collapsePageIcon];

    [[[_collapsePageIcon centerXAnchor] constraintEqualToAnchor:[[self collectionView] centerXAnchor]] setActive:YES];
    [[[_collapsePageIcon widthAnchor] constraintEqualToConstant:100] setActive:YES];
    [[[_collapsePageIcon heightAnchor] constraintEqualToConstant:60] setActive:YES];
    [[[_collapsePageIcon bottomAnchor] constraintEqualToAnchor:[[self collectionView] topAnchor] constant:-25] setActive:YES];

    [_collapseGridIcon setAlpha:0];
    [_collapsePageIcon setAlpha:0];

    _transitionComplete = YES;
    _scale = 1.0;

    [[self collectionView] addObserver:self forKeyPath:@"collectionViewLayout" options:NSKeyValueObservingOptionOld context:nil];
}

#pragma mark - Layout Helpers

-(UICollectionViewTransitionLayout*)activeTransitionLayout{
    return [[[self collectionView] collectionViewLayout] isKindOfClass:[UICollectionViewTransitionLayout class]] ? (UICollectionViewTransitionLayout*) [[self collectionView] collectionViewLayout] : nil;
}

- (__kindof MMShelfLayout*)currentLayout{
    return (MMShelfLayout*)([self activeTransitionLayout] ? [[self activeTransitionLayout] currentLayout] : [[self collectionView] collectionViewLayout]);
}

#pragma mark - Gestures

- (void)pinchGesture:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    if ([[self currentLayout] isShelfLayout]) {
        [self pinchFromShelf:pinchGesture];
    } else if ([[self currentLayout] isPageLayout]) {
        [self pinchFromPage:pinchGesture];
    } else if ([[self currentLayout] isGridLayout]) {
        [self pinchFromGrid:pinchGesture];
    }
}

- (void)pinchFromShelf:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    UICollectionViewTransitionLayout *transitionLayout = [self activeTransitionLayout];
    
    if (!transitionLayout && [pinchGesture state] == UIGestureRecognizerStateBegan) {
        NSIndexPath *targetPath = [[self collectionView] indexPathForItemAtPoint:[pinchGesture locationInView:[self collectionView]]];

        MMGridLayout *pageGridLayout = [self newGridLayoutForSection:[targetPath section]];
        [pageGridLayout setTargetIndexPath:targetPath];

        if (targetPath) {
            _transitionComplete = NO;
            [[self collectionView] startInteractiveTransitionToCollectionViewLayout:pageGridLayout completion:^(BOOL completed, BOOL finished) {
                self->_targetIndexPath = nil;
            }];
        }
    } else if (transitionLayout && [pinchGesture state] == UIGestureRecognizerStateChanged) {
        // 1 if we've completed the transition to the new layout, 0 if we are at the existing layout
        CGFloat progress;

        if (pinchGesture.scale > 1) {
            CGFloat const kMaxGestureScale = 3.0;
            progress = MAX(0, MIN(kMaxGestureScale, ABS(pinchGesture.scale - 1))) / kMaxGestureScale;
        } else {
            progress = 0;
        }

        transitionLayout.transitionProgress = progress;
        [transitionLayout invalidateLayout];
    } else if (!_transitionComplete && transitionLayout && [pinchGesture state] == UIGestureRecognizerStateEnded) {
        _transitionComplete = YES;
        if ([pinchGesture scaleDirection] > 0) {
            [[self collectionView] finishInteractiveTransition];
        } else {
            [[self collectionView] cancelInteractiveTransition];
        }
    } else if (!_transitionComplete && transitionLayout) {
        _transitionComplete = YES;
        [[self collectionView] cancelInteractiveTransition];
    }
}

- (void)pinchFromGrid:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    UICollectionViewTransitionLayout *transitionLayout = [self activeTransitionLayout];
    
    if ([pinchGesture state] == UIGestureRecognizerStateBegan) {
        _targetIndexPath = [[self collectionView] closestIndexPathForPoint:[pinchGesture locationInView:[self collectionView]]];
    } else if (_targetIndexPath && [pinchGesture state] == UIGestureRecognizerStateChanged) {
        if (transitionLayout) {
            BOOL toPage = [[transitionLayout nextLayout] isKindOfClass:[MMPageLayout class]];
            CGFloat progress;

            if (toPage) {
                if (pinchGesture.scale > 1) {
                    CGFloat const kMaxGestureScale = 3.0;
                    progress = MAX(0, MIN(kMaxGestureScale, ABS(pinchGesture.scale - 1))) / kMaxGestureScale;
                } else {
                    progress = 0;
                }
            } else {
                if (pinchGesture.scale < 1) {
                    progress = MAX(0, MIN(1, 1 - ABS(pinchGesture.scale)));
                } else {
                    progress = 0;
                }
            }

            transitionLayout.transitionProgress = progress;
            [transitionLayout invalidateLayout];
        } else {
            UICollectionViewLayout *nextLayout;
            if (pinchGesture.scaleDirection > 0) {
                // transition into page view
                MMPageLayout *pageLayout = [self newPageLayoutForSection:[[self currentLayout] section]];
                [pageLayout setTargetIndexPath:_targetIndexPath];
                nextLayout = pageLayout;
            } else {
                // transition into shelf
                MMShelfLayout *shelfLayout = [self newShelfLayout];
                [shelfLayout setTargetIndexPath:[NSIndexPath indexPathForRow:0 inSection:[[self currentLayout] section]]];
                nextLayout = shelfLayout;
            }

            _transitionComplete = NO;
            [[self collectionView] startInteractiveTransitionToCollectionViewLayout:nextLayout completion:^(BOOL completed, BOOL finished) {
                self->_targetIndexPath = nil;
            }];
        }
    } else if (!_transitionComplete && transitionLayout && [pinchGesture state] == UIGestureRecognizerStateEnded) {
        BOOL toPage = [[transitionLayout nextLayout] isKindOfClass:[MMPageLayout class]];
        _transitionComplete = YES;

        if (toPage && pinchGesture.scaleDirection > 0) {
            [[self collectionView] finishInteractiveTransition];
        } else if (!toPage && pinchGesture.scaleDirection < 0) {
            [[self collectionView] finishInteractiveTransition];
        } else {
            [[self collectionView] cancelInteractiveTransition];
        }
    } else if (!_transitionComplete && transitionLayout) {
        _transitionComplete = YES;
        [[self collectionView] cancelInteractiveTransition];
    }
}

- (void)pinchFromPage:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    UICollectionViewTransitionLayout *transitionLayout = [self activeTransitionLayout];
    CGPoint locInView = [pinchGesture locationInView:[[self collectionView] superview]];
    locInView.x -= [[self collectionView] frame].origin.x;
    locInView.y -= [[self collectionView] frame].origin.y;

    if ([pinchGesture state] == UIGestureRecognizerStateBegan) {

        _targetIndexPath = [[self collectionView] closestIndexPathForPoint:[pinchGesture locationInView:[self collectionView]]];
        _zoomOffset = [[self collectionView] contentOffset];
        _zoomOffset.x += locInView.x;
        _zoomOffset.y += locInView.y;
    } else if ([pinchGesture state] == UIGestureRecognizerStateChanged) {
        if (transitionLayout) {
            BOOL toPage = [[transitionLayout nextLayout] isKindOfClass:[MMPageLayout class]];
            CGFloat progress;

            if (toPage) {
                if (pinchGesture.scale > 1) {
                    CGFloat const kMaxGestureScale = 3.0;
                    progress = MAX(0, MIN(kMaxGestureScale, ABS(pinchGesture.scale - 1))) / kMaxGestureScale;
                } else {
                    progress = 0;
                }
            } else {
                if (pinchGesture.scale < 1) {
                    progress = MAX(0, MIN(1, 1 - ABS(pinchGesture.scale)));
                } else {
                    progress = 0;
                }
            }

            transitionLayout.transitionProgress = progress;
            [transitionLayout invalidateLayout];
        } else {
            NSIndexPath *targetPath = [[self collectionView] indexPathForItemAtPoint:[pinchGesture locationInView:[self collectionView]]];

            UICollectionViewLayout *nextLayout;
            if ((!_isZoomingPage && pinchGesture.scaleDirection > 0) || [_isZoomingPage boolValue] || _scale > 1.0) {
                // scale page up
                if(![_isZoomingPage boolValue]){
                    [self willBeginZoom];
                }
                
                _isZoomingPage = @(YES);
                [[self currentLayout] invalidateLayout];
                
                CGPoint updatedOffset = _zoomOffset;
                CGFloat minScale = 1.0 / _scale;
                updatedOffset.x *= MAX(minScale, pinchGesture.scale);
                updatedOffset.y *= MAX(minScale, pinchGesture.scale);
                
                updatedOffset.x -= locInView.x;
                updatedOffset.y -= locInView.y;
                
                // now make sure our offset is sane according
                // to the min/max allowed offset for ou content size
                CGFloat offset = [[self currentLayout] collectionViewContentSize].width - CGRectGetWidth([[self collectionView] bounds]);
                
                updatedOffset.x = MAX(0, updatedOffset.x);
                updatedOffset.x = MIN(offset, updatedOffset.x);

                [[self collectionView] setContentOffset:updatedOffset animated:NO];
            } else if(!_isZoomingPage || ![_isZoomingPage boolValue]){
                _isZoomingPage = @(NO);
                // transition into grid
                MMGridLayout *gridLayout = [self newGridLayoutForSection:[targetPath section]];
                [gridLayout setTargetIndexPath:targetPath];
                nextLayout = gridLayout;

                _transitionComplete = NO;
                [[self collectionView] startInteractiveTransitionToCollectionViewLayout:nextLayout completion:^(BOOL completed, BOOL finished) {
                    self->_targetIndexPath = nil;
                }];
            }
        }
    } else if ([pinchGesture state] == UIGestureRecognizerStateEnded) {
        if(!_transitionComplete && transitionLayout){
            if ([pinchGesture scaleDirection] < 0) {
                [[self collectionView] finishInteractiveTransition];
            } else {
                [[self collectionView] cancelInteractiveTransition];
            }

        }
        if([_isZoomingPage boolValue]){
            _scale = MAX(1.0, _scale * [_pinchGesture scale]);
        }
        _transitionComplete = YES;
        _isZoomingPage = nil;
        [self didEndZoom];
    } else {
        if(!_transitionComplete && transitionLayout){
            [[self collectionView] cancelInteractiveTransition];
        }else{
            [[self currentLayout] invalidateLayout];
        }

        _isZoomingPage = nil;
        _transitionComplete = YES;
        [self didCancelZoom];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    @throw [NSException exceptionWithName:@"AbstractMethodException" reason:[NSString stringWithFormat:@"Must override %@", NSStringFromSelector(_cmd)] userInfo:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    @throw [NSException exceptionWithName:@"AbstractMethodException" reason:[NSString stringWithFormat:@"Must override %@", NSStringFromSelector(_cmd)] userInfo:nil];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MMPageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([MMPageCollectionCell class]) forIndexPath:indexPath];
    MMShelfLayout *layout = (MMShelfLayout *)[collectionView collectionViewLayout];
    layout = [layout isKindOfClass:[UICollectionViewTransitionLayout class]] ? (MMShelfLayout *)[(UICollectionViewTransitionLayout *)layout nextLayout] : layout;

    [[cell textLabel] setText:[NSString stringWithFormat:@"%@,%@", @(indexPath.section), @(indexPath.row)]];

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        MMPageCollectionHeader *header = (MMPageCollectionHeader *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([MMPageCollectionHeader class]) forIndexPath:indexPath];
        [header setIndexPath:indexPath];

        return header;
    }

    return nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat const min = 70;
    CGFloat const dist = 40;
    CGFloat progress = MIN(-min, MAX(-(min + dist), scrollView.contentOffset.y));
    progress = ABS(min + progress) / dist;

    if ([[self currentLayout] isGridLayout]) {
        [_collapseGridIcon setProgress:progress];
        [_collapsePageIcon setProgress:0];
    } else if ([[self currentLayout] isPageLayout]) {
        [_collapseGridIcon setProgress:0];
        [_collapsePageIcon setProgress:progress];
    } else {
        [_collapseGridIcon setProgress:0];
        [_collapsePageIcon setProgress:0];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.contentOffset.y < -100 && ([[self currentLayout] isGridLayout] || [[self currentLayout] isPageLayout])) {
        // turn off bounce during this animation, as the bounce from the scrollview
        // being overscrolled conflicts with the layout animation
        [[self collectionView] setBounces:NO];
        MMShelfLayout *nextLayout;

        if ([[self currentLayout] isGridLayout]) {
            nextLayout = [self newShelfLayout];
            [nextLayout setTargetIndexPath:[NSIndexPath indexPathForRow:0 inSection:[[self currentLayout] section]]];
        } else if ([[self currentLayout] isPageLayout]) {
            nextLayout = [self newGridLayoutForSection:[[self currentLayout] section]];
        }

        [[self collectionView] setCollectionViewLayout:nextLayout animated:YES completion:^(BOOL finished) {
            [[self collectionView] setBounces:YES];
        }];
    }
}

#pragma mark - Collection View

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MMGridLayout *updatedLayout;
    if ([[self currentLayout] isShelfLayout]) {
        updatedLayout = [self newGridLayoutForSection:[indexPath section]];
    } else if ([[self currentLayout] isGridLayout] && ![self activeTransitionLayout]) {
        updatedLayout = [self newPageLayoutForSection:[indexPath section]];
        [updatedLayout setTargetIndexPath:indexPath];
    }

    if(updatedLayout){
        [[self collectionView] setCollectionViewLayout:updatedLayout animated:YES completion:nil];
    }
}

#pragma mark - Shelf Layout

- (id<MMShelfLayoutObject>)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout objectAtIndexPath:(NSIndexPath *)indexPath{
    @throw [NSException exceptionWithName:@"AbstractMethodException" reason:[NSString stringWithFormat:@"Must override %@", NSStringFromSelector(_cmd)] userInfo:nil];
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(MMPageLayout *)collectionViewLayout zoomScaleForIndexPath:(NSIndexPath *)indexPath{
    return [self scale];
}

#pragma mark - Layout Changes

- (void)collectionView:(UICollectionView *)collectionView willChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout
{
    if ([newLayout isMemberOfClass:[MMGridLayout class]]) {
        [_collapseGridIcon setAlpha:1];
        [_collapsePageIcon setAlpha:0];
    } else if ([newLayout isMemberOfClass:[MMPageLayout class]]) {
        [_collapseGridIcon setAlpha:0];
        [_collapsePageIcon setAlpha:1];
    } else {
        [_collapseGridIcon setAlpha:0];
        [_collapsePageIcon setAlpha:0];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout
{
    if ([newLayout isKindOfClass:[MMShelfLayout class]]) {
        [(MMShelfLayout *)newLayout setTargetIndexPath:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    [self collectionView:[self collectionView] willChangeToLayout:[[self collectionView] collectionViewLayout] fromLayout:[change objectForKey:NSKeyValueChangeOldKey]];
}

#pragma mark - Subclasses

-(CGFloat)scale{
    CGFloat scale = _scale;
    
    if([_isZoomingPage boolValue]){
        scale = MAX(1.0, scale * [_pinchGesture scale]);
    }
    
    return scale;
}

-(MMShelfLayout*)newShelfLayout{
    return [[MMShelfLayout alloc] init];
}

-(MMGridLayout*)newGridLayoutForSection:(NSUInteger)section{
    return [[MMGridLayout alloc] initWithSection:section];
}

-(MMPageLayout*)newPageLayoutForSection:(NSUInteger)section{
    return [[MMPageLayout alloc] initWithSection:section];
}

-(void)willBeginZoom{
    // noop, available for subclasses
}

-(void)didEndZoom{
    // noop, available for subclasses
}

-(void)didCancelZoom{
    // noop, available for subclasses
}

@end
