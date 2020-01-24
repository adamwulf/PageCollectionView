//
//  MMPageCollectionViewController.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/5/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageCollectionViewController.h"
#import "MMPageCollectionViewController+Protected.h"
#import "MMPinchVelocityGestureRecognizer.h"
#import "MMPageCollectionView.h"
#import "MMPageCollectionView+Protected.h"
#import "MMPageCollectionCell.h"
#import "MMPageCollectionHeader.h"
#import "MMGridIconView.h"
#import "MMVerticalPageIconView.h"
#import "MMShelfLayout.h"
#import "MMGridLayout.h"
#import "MMPageLayout.h"

#define CLAMPF(v, minFr, maxFr, minTo, maxTo) (((v - minFr) / (maxFr - minFr)) * (maxTo - minTo) + minTo)

static CGFloat const kMinGestureScale = 1.0;
static CGFloat const kMaxGestureScale = 4.0;


@interface MMPageCollectionViewController () <MMPageCollectionViewDelegate>

@property(nonatomic, readonly) CGFloat maxPageScale;
@property(nonatomic, readonly) CGFloat pageScale;

@property(nonatomic, strong) IBOutlet MMPageCollectionView *collectionView;
@property(nonatomic, strong) UICollectionViewFlowLayout *pageLayout;

@end


typedef enum : NSUInteger {
    MMScalingNone = 0,
    MMScalingPage,
    MMScalingToGrid,
} MMScalingDirection;


@implementation MMPageCollectionViewController {
    NSIndexPath *_targetIndexPath;
    MMGridIconView *_collapseGridIcon;
    MMVerticalPageIconView *_collapseVerticalPageIcon;
    CGPoint _zoomPercentOffset;
    MMScalingDirection _isZoomingPage;
    MMPinchVelocityGestureRecognizer *_pinchGesture;
}

@synthesize pageScale = _pageScale;

- (instancetype)init
{
    if (self = [super init]) {
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

    _collapseVerticalPageIcon = [[MMVerticalPageIconView alloc] initWithFrame:CGRectZero];
    [_collapseVerticalPageIcon setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self collectionView] addSubview:_collapseVerticalPageIcon];

    [[[_collapseVerticalPageIcon centerXAnchor] constraintEqualToAnchor:[[self collectionView] centerXAnchor]] setActive:YES];
    [[[_collapseVerticalPageIcon widthAnchor] constraintEqualToConstant:100] setActive:YES];
    [[[_collapseVerticalPageIcon heightAnchor] constraintEqualToConstant:60] setActive:YES];
    [[[_collapseVerticalPageIcon bottomAnchor] constraintEqualToAnchor:[[self collectionView] topAnchor] constant:-25] setActive:YES];

    [_collapseGridIcon setAlpha:0];
    [_collapseVerticalPageIcon setAlpha:0];

    _pageScale = 1.0;

    [[self collectionView] addObserver:self forKeyPath:@"collectionViewLayout" options:NSKeyValueObservingOptionOld context:nil];
    [[self collectionView] setAlwaysBounceVertical:[[[self collectionView] currentLayout] bounceVertical]];
    [[self collectionView] setAlwaysBounceHorizontal:[[[self collectionView] currentLayout] bounceHorizontal]];
}

#pragma mark - UIViewController

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [[[self collectionView] collectionViewLayout] invalidateLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context){

    }];
}

#pragma mark - Layout Helpers

- (BOOL)isDisplayingShelf
{
    return [[[self collectionView] currentLayout] isMemberOfClass:[MMShelfLayout class]];
}

- (BOOL)isDisplayingGrid
{
    return [[[self collectionView] currentLayout] isMemberOfClass:[MMGridLayout class]];
}

- (BOOL)isDisplayingPage
{
    return [[[self collectionView] currentLayout] isMemberOfClass:[MMPageLayout class]];
}

#pragma mark - Gestures

- (void)reenablePinchGesture
{
    [_pinchGesture setEnabled:YES];
}

- (void)brieflyDisablePinchGesture
{
    [_pinchGesture setEnabled:NO];
    [self performSelector:@selector(reenablePinchGesture) withObject:nil afterDelay:.5];
}

- (void)pinchGesture:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    if ([self isDisplayingShelf]) {
        [self pinchFromShelf:pinchGesture];
    } else if ([self isDisplayingGrid]) {
        [self pinchFromGrid:pinchGesture];
    } else if ([self isDisplayingPage]) {
        [self pinchFromPage:pinchGesture];
    }
}

- (void)pinchFromShelf:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    UICollectionViewTransitionLayout *transitionLayout = [[self collectionView] activeTransitionLayout];

    if (!transitionLayout && [pinchGesture state] == UIGestureRecognizerStateBegan) {
        NSIndexPath *targetPath = [[self collectionView] closestIndexPathForPoint:[pinchGesture locationInView:[self collectionView]]];
        MMGridLayout *pageGridLayout = [self newGridLayoutForSection:[targetPath section]];

        [pageGridLayout setTargetIndexPath:targetPath];

        if (targetPath) {
            [[self collectionView] startInteractiveTransitionToCollectionViewLayout:pageGridLayout completion:^(BOOL completed, BOOL finished) {
                self->_targetIndexPath = nil;
            }];
        }
    } else if (transitionLayout && [pinchGesture state] == UIGestureRecognizerStateChanged) {
        // 1 if we've completed the transition to the new layout, 0 if we are at the existing layout
        CGFloat progress;

        if (pinchGesture.scale > 1) {
            // when pinching to zoom into a document from the shelf, the gesture scale
            // starts at 1 and increases with the zoom. Below, we clamp the pinch
            //  from 1x -> 4x and divide that by 3.0 to get a smooth transition from
            // 1x -> 3x maps to  0 -> 1
            progress = CLAMPF(pinchGesture.scale, kMinGestureScale, kMaxGestureScale, 0, 1);
        } else {
            progress = 0;
        }

        transitionLayout.transitionProgress = progress;
        [transitionLayout invalidateLayout];
    } else if (transitionLayout && [pinchGesture state] == UIGestureRecognizerStateEnded) {
        if ([pinchGesture scaleDirection] > 0) {
            [[self collectionView] finishInteractiveTransition];
        } else {
            [[self collectionView] cancelInteractiveTransition];
        }
    } else if (transitionLayout) {
        [[self collectionView] cancelInteractiveTransition];
    }
}

- (void)pinchFromGrid:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    UICollectionViewTransitionLayout *transitionLayout = [[self collectionView] activeTransitionLayout];

    if ([pinchGesture state] == UIGestureRecognizerStateBegan) {
        _targetIndexPath = [[self collectionView] closestIndexPathForPoint:[pinchGesture locationInView:[self collectionView]]];
    } else if (_targetIndexPath && [pinchGesture state] == UIGestureRecognizerStateChanged) {
        if (transitionLayout) {
            BOOL toPage = [[transitionLayout nextLayout] isKindOfClass:[MMPageLayout class]];
            CGFloat progress;

            if (toPage) {
                if (pinchGesture.scale > 1) {
                    progress = CLAMPF(pinchGesture.scale, kMinGestureScale, kMaxGestureScale, 0, 1);
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
                MMPageLayout *pageLayout = [self newPageLayoutForSection:[[[self collectionView] currentLayout] section]];
                [pageLayout setTargetIndexPath:_targetIndexPath];
                nextLayout = pageLayout;
            } else {
                // transition into shelf
                MMShelfLayout *shelfLayout = [self newShelfLayout];
                [shelfLayout setTargetIndexPath:[NSIndexPath indexPathForRow:0 inSection:[[[self collectionView] currentLayout] section]]];
                nextLayout = shelfLayout;
            }

            [[self collectionView] startInteractiveTransitionToCollectionViewLayout:nextLayout completion:^(BOOL completed, BOOL finished) {
                self->_targetIndexPath = nil;
            }];
        }
    } else if (transitionLayout && [pinchGesture state] == UIGestureRecognizerStateEnded) {
        BOOL toPage = [[transitionLayout nextLayout] isKindOfClass:[MMPageLayout class]];

        if (toPage && pinchGesture.scaleDirection > 0) {
            [[self collectionView] finishInteractiveTransition];
        } else if (!toPage && pinchGesture.scaleDirection < 0) {
            [[self collectionView] finishInteractiveTransition];
        } else {
            [[self collectionView] cancelInteractiveTransition];
        }
    } else if (transitionLayout) {
        [[self collectionView] cancelInteractiveTransition];
    }
}

- (void)pinchFromPage:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    UICollectionViewTransitionLayout *transitionLayout = [[self collectionView] activeTransitionLayout];
    CGPoint locInView = [pinchGesture locationInView:[[self collectionView] superview]];
    locInView.x -= [[self collectionView] frame].origin.x;
    locInView.y -= [[self collectionView] frame].origin.y;

    if ([pinchGesture state] == UIGestureRecognizerStateBegan) {
        CGPoint gestureLocInContent = [pinchGesture locationInView:[self collectionView]];
        _targetIndexPath = [[self collectionView] closestIndexPathForPoint:gestureLocInContent];
        _zoomPercentOffset.x = gestureLocInContent.x / [[self collectionView] contentSize].width;
        _zoomPercentOffset.y = gestureLocInContent.y / [[self collectionView] contentSize].height;

        if (!_targetIndexPath) {
            // cancel if we can't find a target index
            [pinchGesture setEnabled:NO];
            [pinchGesture setEnabled:YES];
        }
    } else if ([pinchGesture state] == UIGestureRecognizerStateChanged) {
        if (transitionLayout) {
            BOOL toPage = [[transitionLayout nextLayout] isKindOfClass:[MMPageLayout class]];
            CGFloat progress;

            if (toPage) {
                if (pinchGesture.scale > 1) {
                    progress = CLAMPF(pinchGesture.scale, kMinGestureScale, kMaxGestureScale, 0, 1);
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
            if ((_isZoomingPage == MMScalingNone && pinchGesture.scaleDirection > 0) || _isZoomingPage == MMScalingPage || _pageScale > 1.0) {
                // scale page up
                _isZoomingPage = MMScalingPage;

                // when zooming, to get a clean zoom animation we need to
                // reset the entire layout, as this will trigger targetContentOffsetForProposedContentOffset:
                // so that our layout + offset change will happen at the exact same time.
                // this prevents the offset from jumping around during the gesture, and also
                // prevents us invalidating the layout when setting the offset manually.
                MMPageLayout *layout = [[MMPageLayout alloc] initWithSection:[_targetIndexPath section]];
                // which page is being held
                [layout setTargetIndexPath:_targetIndexPath];
                // what % in both direction its held
                [layout setStartingPercentOffset:_zoomPercentOffset];
                // where the gesture is in collection view coordiates
                [layout setGestureRecognizer:_pinchGesture];
                [layout setFitWidth:[[[self collectionView] currentLayout] fitWidth]];
                [layout setDirection:[[[self collectionView] currentLayout] direction]];

                [[[self collectionView] currentLayout] setTargetIndexPath:_targetIndexPath];
                [[[self collectionView] currentLayout] setStartingPercentOffset:_zoomPercentOffset];
                [[[self collectionView] currentLayout] setGestureRecognizer:_pinchGesture];

                // Can't call [invalidateLayout] here, as this won't cause the collectionView to
                // ask for targetContentOffsetForProposedContentOffset:. This means the contentOffset
                // will remain exactly in place as the content scales. Setting a layout will
                // ask for a targetContentOffset, so we can keep the page in view while we scale.
                [[self collectionView] setCollectionViewLayout:layout animated:NO];
            } else if (_isZoomingPage == MMScalingNone || _isZoomingPage == MMScalingToGrid) {
                _isZoomingPage = MMScalingToGrid;
                // transition into grid
                MMGridLayout *gridLayout = [self newGridLayoutForSection:[_targetIndexPath section]];
                [gridLayout setTargetIndexPath:_targetIndexPath];

                [[self collectionView] startInteractiveTransitionToCollectionViewLayout:gridLayout completion:^(BOOL completed, BOOL finished) {
                    self->_targetIndexPath = nil;
                }];
            }
        }
    } else if ([pinchGesture state] == UIGestureRecognizerStateEnded) {
        if (transitionLayout) {
            if ([pinchGesture scaleDirection] < 0) {
                [[self collectionView] finishInteractiveTransition];
            } else {
                [[self collectionView] cancelInteractiveTransition];
            }
        }
        if (_isZoomingPage == MMScalingPage) {
            // we've finished zoom into our page, save the final scale
            _pageScale = MIN(MAX(1.0, _pageScale * [_pinchGesture scale]), [self maxPageScale]);
        }
        _isZoomingPage = MMScalingNone;
        [[[self collectionView] currentLayout] setStartingPercentOffset:CGPointZero];
        [[[self collectionView] currentLayout] setGestureRecognizer:nil];
    } else {
        if (transitionLayout) {
            [[self collectionView] cancelInteractiveTransition];
        } else {
            [[[self collectionView] currentLayout] invalidateLayout];
        }

        _isZoomingPage = MMScalingNone;
        [[[self collectionView] currentLayout] setStartingPercentOffset:CGPointZero];
        [[[self collectionView] currentLayout] setGestureRecognizer:nil];
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

    if ([self isDisplayingGrid]) {
        [_collapseGridIcon setProgress:progress];
        [_collapseVerticalPageIcon setProgress:0];
    } else if ([self isDisplayingPage] && [[[self collectionView] currentLayout] direction] == MMPageLayoutVertical) {
        [_collapseGridIcon setProgress:0];
        [_collapseVerticalPageIcon setProgress:progress];
    } else {
        [_collapseGridIcon setProgress:0];
        [_collapseVerticalPageIcon setProgress:0];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    BOOL isVerticalPage = [self isDisplayingPage] && [[[self collectionView] currentLayout] direction] == MMPageLayoutVertical;

    if (scrollView.contentOffset.y < -100 && ([self isDisplayingGrid] || isVerticalPage)) {
        // turn off bounce during this animation, as the bounce from the scrollview
        // being overscrolled conflicts with the layout animation
        MMShelfLayout *nextLayout;

        if ([self isDisplayingGrid]) {
            nextLayout = [self newShelfLayout];
            [nextLayout setTargetIndexPath:[NSIndexPath indexPathForRow:0 inSection:[[[self collectionView] currentLayout] section]]];
        } else if ([self isDisplayingPage]) {
            nextLayout = [self newGridLayoutForSection:[[[self collectionView] currentLayout] section]];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[self collectionView] setCollectionViewLayout:nextLayout animated:YES completion:nil];
        });
    }
}

#pragma mark - Collection View

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MMGridLayout *updatedLayout;
    if ([self isDisplayingShelf]) {
        updatedLayout = [self newGridLayoutForSection:[indexPath section]];
    } else if ([self isDisplayingGrid] && ![[self collectionView] activeTransitionLayout]) {
        updatedLayout = [self newPageLayoutForSection:[indexPath section]];
        [updatedLayout setTargetIndexPath:indexPath];
    }

    if (updatedLayout) {
        [[self collectionView] setCollectionViewLayout:updatedLayout animated:YES completion:nil];
    }
}

#pragma mark - Shelf Layout

- (id<MMShelfLayoutObject>)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout objectAtIndexPath:(NSIndexPath *)indexPath
{
    @throw [NSException exceptionWithName:@"AbstractMethodException" reason:[NSString stringWithFormat:@"Must override %@", NSStringFromSelector(_cmd)] userInfo:nil];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(MMPageLayout *)collectionViewLayout zoomScaleForIndexPath:(NSIndexPath *)indexPath
{
    return [self pageScale];
}

#pragma mark - Layout Changes

- (void)collectionView:(UICollectionView *)collectionView willChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout
{
    if ([newLayout isMemberOfClass:[MMGridLayout class]]) {
        [_collapseGridIcon setAlpha:1];
        [_collapseVerticalPageIcon setAlpha:0];
    } else if ([newLayout isMemberOfClass:[MMPageLayout class]] && [(MMPageLayout *)newLayout direction] == MMPageLayoutVertical) {
        [_collapseGridIcon setAlpha:0];
        [_collapseVerticalPageIcon setAlpha:1];
    } else {
        [_collapseGridIcon setAlpha:0];
        [_collapseVerticalPageIcon setAlpha:0];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout
{
    if ([newLayout isKindOfClass:[MMShelfLayout class]]) {
        [(MMShelfLayout *)newLayout setTargetIndexPath:nil];
        [[self collectionView] setAlwaysBounceVertical:[(MMShelfLayout *)newLayout bounceVertical]];
        [[self collectionView] setAlwaysBounceHorizontal:[(MMShelfLayout *)newLayout bounceHorizontal]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didFinalizeTransitionLayout:(UICollectionViewTransitionLayout *)transitionLayout
{
    // Disable pinching during a transition animation. This delegate method is called for any
    // finishInteractiveTransition or cancelInteractiveTransition. This lets us turn off the
    // pinch gesture for a small time while the animation completes, then it will re-enable.
    [self brieflyDisablePinchGesture];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    [self collectionView:[self collectionView] willChangeToLayout:[[self collectionView] collectionViewLayout] fromLayout:[change objectForKey:NSKeyValueChangeOldKey]];
}

#pragma mark - Subclasses

- (CGFloat)maxPageScale
{
    return 300;
}

- (CGFloat)pageScale
{
    CGFloat scale = _pageScale;

    if (_isZoomingPage == MMScalingPage) {
        scale = MIN(MAX(1.0, scale * [_pinchGesture scale]), [self maxPageScale]);
    }

    return scale;
}

- (MMShelfLayout *)newShelfLayout
{
    return [[MMShelfLayout alloc] init];
}

- (MMGridLayout *)newGridLayoutForSection:(NSUInteger)section
{
    return [[MMGridLayout alloc] initWithSection:section];
}

- (MMPageLayout *)newPageLayoutForSection:(NSUInteger)section
{
    return [[MMPageLayout alloc] initWithSection:section];
}

@end
