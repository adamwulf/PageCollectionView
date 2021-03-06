//
//  SampleCollectionViewController.m
//  PageCollectionViewSample
//
//  Created by Adam Wulf on 10/15/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "SampleCollectionViewController.h"
#import "MMPageCollectionView+Protected.h"
#import "SampleObject.h"


@interface SampleCollectionViewController () <MMPageCollectionViewDataSourceShelfLayout>

@property(nonatomic, strong) NSArray<SampleObject *> *objects;

@property(nonatomic, strong) IBOutlet UIButton *rotateButton;
@property(nonatomic, strong) IBOutlet UIButton *bumpButton;
@property(nonatomic, strong) IBOutlet UIButton *resetButton;
@property(nonatomic, strong) IBOutlet UIButton *fitWidthButton;
@property(nonatomic, strong) IBOutlet UIButton *directionButton;

@end


@implementation SampleCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray<SampleObject *> *arr = [NSMutableArray array];

    CGFloat fullWidth = CGRectGetWidth([[self collectionView] bounds]);

    for (NSInteger i = 0; i < 100; i++) {
        SampleObject *obj = [[SampleObject alloc] init];

        if (i % 5 == 0) {
            [obj setRotation:M_PI_2];
        }

        if (i % 7 == 0) {
            [obj setIdealSize:CGSizeMake(fullWidth / 2, 1.4 * fullWidth / 2)];
        } else {
            // 8.5x11
            [obj setIdealSize:CGSizeMake(612, 792)];
        }

        // example scale to show PDF at physical size
        [obj setPhysicalScale:1.4];

        [arr addObject:obj];
    }

    _objects = arr;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if ([[[self collectionView] collectionViewLayout] isMemberOfClass:[MMPageLayout class]]) {
        MMPageLayout *layout = (MMPageLayout *)[[self collectionView] collectionViewLayout];
        CGPoint center = [[self collectionView] contentOffset];
        center.x += [[self collectionView] bounds].size.width / 2;
        center.y += [[self collectionView] bounds].size.height / 2;

        NSIndexPath *indexPath = [[self collectionView] closestIndexPathForPoint:center];

        [layout setTargetIndexPath:indexPath];
        [[[self collectionView] collectionViewLayout] invalidateLayout];

        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {

        } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            [layout setTargetIndexPath:nil];
        }];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // for this example, we'll just show the same collection three times
    return 10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_objects count];
}

#pragma mark - Actions

- (IBAction)rotate:(id)sender
{
    CGPoint center = [[self collectionView] contentOffset];
    center.x += [[self collectionView] bounds].size.width / 2;
    center.y += [[self collectionView] bounds].size.height / 2;

    NSIndexPath *indexPath = [[self collectionView] closestIndexPathForPoint:center];

    SampleObject *obj = [_objects objectAtIndex:[indexPath row]];

    [obj setRotation:[obj rotation] - M_PI_2];

    MMPageLayout *layout = [[MMPageLayout alloc] initWithSection:[indexPath section]];
    [layout setTargetIndexPath:indexPath];
    [layout setDirection:[[[self collectionView] currentLayout] direction]];
    [layout setFitWidth:[[[self collectionView] currentLayout] fitWidth]];

    [[self collectionView] setCollectionViewLayout:layout animated:YES];
}

- (IBAction)bump:(id)sender
{
    CGPoint center = [[self collectionView] contentOffset];
    center.x += [[self collectionView] bounds].size.width / 2;
    center.y += [[self collectionView] bounds].size.height / 2;

    NSIndexPath *indexPath = [[self collectionView] closestIndexPathForPoint:center];

    SampleObject *obj = [_objects objectAtIndex:[indexPath row]];

    [obj setRotation:[obj rotation] - .1];

    MMPageLayout *layout = [[MMPageLayout alloc] initWithSection:[indexPath section]];
    [layout setTargetIndexPath:indexPath];
    [layout setDirection:[[[self collectionView] currentLayout] direction]];
    [layout setFitWidth:[[[self collectionView] currentLayout] fitWidth]];

    [[self collectionView] setCollectionViewLayout:layout animated:YES];
}

- (IBAction)reset:(id)sender
{
    CGPoint center = [[self collectionView] contentOffset];
    center.x += [[self collectionView] bounds].size.width / 2;
    center.y += [[self collectionView] bounds].size.height / 2;

    NSIndexPath *indexPath = [[self collectionView] closestIndexPathForPoint:center];

    SampleObject *obj = [_objects objectAtIndex:[indexPath row]];

    [obj setRotation:0];

    MMPageLayout *layout = [[MMPageLayout alloc] initWithSection:[indexPath section]];
    [layout setTargetIndexPath:indexPath];
    [layout setDirection:[[[self collectionView] currentLayout] direction]];
    [layout setFitWidth:[[[self collectionView] currentLayout] fitWidth]];

    [[self collectionView] setCollectionViewLayout:layout animated:YES];
}

/// Change the scale from actual-size to fit-width
- (IBAction)swapScale:(id)sender
{
    if ([[[self collectionView] currentLayout] isMemberOfClass:[MMPageLayout class]]) {
        CGPoint center = [[self collectionView] contentOffset];
        center.x += [[self collectionView] bounds].size.width / 2;
        center.y += [[self collectionView] bounds].size.height / 2;

        NSIndexPath *indexPath = [[self collectionView] closestIndexPathForPoint:center];
        MMPageLayout *layout = [[MMPageLayout alloc] initWithSection:[indexPath section]];

        [layout setTargetIndexPath:indexPath];
        [layout setFitWidth:![[[self collectionView] currentLayout] fitWidth]];
        [layout setDirection:[[[self collectionView] currentLayout] direction]];

        _pageScale = 1.0;

        [[self collectionView] setCollectionViewLayout:layout animated:YES];
    }
}

- (IBAction)toggleDirection:(id)sender
{
    if ([[[self collectionView] currentLayout] isMemberOfClass:[MMPageLayout class]]) {
        CGPoint center = [[self collectionView] contentOffset];
        center.x += [[self collectionView] bounds].size.width / 2;
        center.y += [[self collectionView] bounds].size.height / 2;

        NSIndexPath *indexPath = [[self collectionView] closestIndexPathForPoint:center];

        MMPageLayout *layout = [[MMPageLayout alloc] initWithSection:[indexPath section]];

        [layout setTargetIndexPath:indexPath];
        [layout setFitWidth:[[[self collectionView] currentLayout] fitWidth]];

        if ([[[self collectionView] currentLayout] direction] == MMPageLayoutVertical) {
            [layout setDirection:MMPageLayoutHorizontal];
        } else {
            [layout setDirection:MMPageLayoutVertical];
        }

        [[self collectionView] setCollectionViewLayout:layout animated:YES];
    }
}

#pragma mark - Shelf Layout

- (id<MMShelfLayoutObject>)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [_objects objectAtIndex:[indexPath row]];
}

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout
{
    [super collectionView:collectionView didChangeToLayout:newLayout fromLayout:oldLayout];

    if ([newLayout isMemberOfClass:[MMPageLayout class]]) {
        [[self rotateButton] setHidden:NO];
        [[self bumpButton] setHidden:NO];
        [[self resetButton] setHidden:NO];
        [[self fitWidthButton] setHidden:NO];
        [[self directionButton] setHidden:NO];
    } else {
        [[self rotateButton] setHidden:YES];
        [[self bumpButton] setHidden:YES];
        [[self resetButton] setHidden:YES];
        [[self fitWidthButton] setHidden:YES];
        [[self directionButton] setHidden:YES];
    }
}

@end
