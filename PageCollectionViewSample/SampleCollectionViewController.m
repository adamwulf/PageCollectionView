//
//  SampleCollectionViewController.m
//  PageCollectionViewSample
//
//  Created by Adam Wulf on 10/15/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "SampleCollectionViewController.h"
#import "SampleObject.h"


@interface SampleCollectionViewController () <MMPageCollectionViewDataSourceShelfLayout>

@property(nonatomic, strong) NSArray<SampleObject *> *objects;

@property(nonatomic, strong) IBOutlet UIButton *rotateButton;
@property(nonatomic, strong) IBOutlet UIButton *bumpButton;
@property(nonatomic, strong) IBOutlet UIButton *resetButton;

@end


@implementation SampleCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray<SampleObject *> *arr = [NSMutableArray array];

    CGFloat fullWidth = CGRectGetWidth([[self collectionView] bounds]);
    CGSize size = CGSizeMake(fullWidth, fullWidth);

    // handle different size items similar to flow layout
    size.height = 1.4 * size.width;

    for (NSInteger i = 0; i < 20; i++) {
        CGFloat rotation = 0;

        if (i % 5 == 0) {
            rotation = M_PI_2;
        }

        SampleObject *obj = [[SampleObject alloc] init];
        [obj setIdealSize:size];
        [obj setRotation:rotation];

        [arr addObject:obj];
    }

    _objects = arr;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // for this example, we'll just show the same collection three times
    return 3;
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

    [[self collectionView] setCollectionViewLayout:layout animated:YES];
}

#pragma mark - Shelf Layout

- (id<MMShelfLayoutObject>)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [_objects objectAtIndex:[indexPath row]];
}

- (void)collectionView:(UICollectionView *)collectionView didChangeToLayout:(UICollectionViewLayout *)newLayout fromLayout:(UICollectionViewLayout *)oldLayout
{
    if ([newLayout isMemberOfClass:[MMPageLayout class]]) {
        [[self rotateButton] setHidden:NO];
        [[self bumpButton] setHidden:NO];
        [[self resetButton] setHidden:NO];
    } else {
        [[self rotateButton] setHidden:YES];
        [[self bumpButton] setHidden:YES];
        [[self resetButton] setHidden:YES];
    }
}

@end
