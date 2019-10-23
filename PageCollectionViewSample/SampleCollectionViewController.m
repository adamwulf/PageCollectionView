//
//  SampleCollectionViewController.m
//  PageCollectionViewSample
//
//  Created by Adam Wulf on 10/15/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "SampleCollectionViewController.h"
#import "SampleObject.h"

@interface SampleCollectionViewController ()<MMPageCollectionViewDataSourceShelfLayout>

@end

@implementation SampleCollectionViewController

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 20;
}

#pragma mark - Shelf Layout

- (id<MMShelfLayoutObject>)collectionView:(UICollectionView *)collectionView layout:(MMShelfLayout *)collectionViewLayout objectAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat fullWidth = CGRectGetWidth([collectionView bounds]);
    CGSize size = CGSizeMake(fullWidth, fullWidth);
    CGFloat rotation = 0;
    
    // handle different size items similar to flow layout
    size.height = 1.4 * size.width;

    if(indexPath.row % 5 == 0){
        rotation = M_PI_2;
    }
    
    SampleObject *obj = [[SampleObject alloc] init];
    [obj setIdealSize:size];
    [obj setRotation:rotation];

    return obj;
}

@end
