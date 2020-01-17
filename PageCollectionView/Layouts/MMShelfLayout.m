//
//  MMShelfLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMShelfLayout.h"


@interface MMShelfLayout ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *shelfCache;
@property(nonatomic, assign) CGFloat contentHeight;
@property(nonatomic, readonly) CGFloat contentWidth;

@end


@implementation MMShelfLayout

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _sectionInsets = UIEdgeInsetsMake(10, 40, 40, 40);
        _shelfCache = [NSMutableArray array];
        _pageSpacing = 40;
        _defaultHeaderSize = CGSizeMake(200, 50);
        _maxDim = 140;
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        _sectionInsets = UIEdgeInsetsMake(10, 40, 40, 40);
        _shelfCache = [NSMutableArray array];
        _pageSpacing = 40;
        _defaultHeaderSize = CGSizeMake(200, 50);
        _maxDim = 140;
    }
    return self;
}

- (BOOL)isShelfLayout
{
    return YES;
}

- (BOOL)isGridLayout
{
    return NO;
}

- (BOOL)isPageLayout
{
    return NO;
}

- (BOOL)bounceVertical
{
    return YES;
}

- (BOOL)bounceHorizontal
{
    return NO;
}

- (id<MMPageCollectionViewDelegateShelfLayout>)delegate
{
    return (id<MMPageCollectionViewDelegateShelfLayout>)[[self collectionView] delegate];
}

- (id<MMPageCollectionViewDataSourceShelfLayout>)datasource
{
    NSAssert([[[self collectionView] dataSource] conformsToProtocol:@protocol(MMPageCollectionViewDataSourceShelfLayout)], @"CollectionView data source must conform to MMPageCollectionViewDataSourceShelfLayout");

    return (id<MMPageCollectionViewDataSourceShelfLayout>)[[self collectionView] dataSource];
}

- (CGFloat)contentWidth
{
    UIEdgeInsets insets = [[self collectionView] contentInset];
    return CGRectGetWidth([[self collectionView] bounds]) - insets.left - insets.right;
}

#pragma mark - UICollectionViewLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !CGSizeEqualToSize([[self collectionView] bounds].size, newBounds.size);
}

- (void)invalidateLayout
{
    [super invalidateLayout];

    [_shelfCache removeAllObjects];
}

- (CGSize)collectionViewContentSize
{
    return CGSizeMake([self contentWidth], _contentHeight);
}

- (void)prepareLayout
{
    CGFloat yOffset = 0;

    if ([_shelfCache count]) {
        // don't relayout if we haven't been invalidated.
        return;
    }

    for (NSInteger section = 0; section < [[self collectionView] numberOfSections]; section++) {
        NSInteger rowCount = [[self collectionView] numberOfItemsInSection:section];
        CGFloat maxItemHeight = 0;
        CGSize headerSize = _defaultHeaderSize;

        // Calculate the header section size, if any
        if ([[self delegate] respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
            headerSize = [[self delegate] collectionView:[self collectionView] layout:self referenceSizeForHeaderInSection:section];
        }

        if (!CGSizeEqualToSize(headerSize, CGSizeZero)) {
            UICollectionViewLayoutAttributes *headerAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
            [headerAttrs setFrame:CGRectMake(0, yOffset, headerSize.width, headerSize.height)];
            [_shelfCache addObject:headerAttrs];

            yOffset += headerSize.height;
        }

        CGFloat xOffset = _sectionInsets.left;
        yOffset += _sectionInsets.top;

        BOOL didFinish = NO;

        // Calculate the size of each row
        for (NSInteger row = 0; row < rowCount; row++) {
            id<MMShelfLayoutObject> object = [[self datasource] collectionView:[self collectionView] layout:self objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            CGSize itemSize = [object idealSize];
            CGFloat rotation = [object rotation];
            CGFloat heightRatio = itemSize.height / itemSize.width;

            if (itemSize.height <= itemSize.width && itemSize.width > [self maxDim]) {
                itemSize.height = [self maxDim] * heightRatio;
                itemSize.width = [self maxDim];
            } else if (itemSize.height >= itemSize.width && itemSize.height > [self maxDim]) {
                itemSize.height = [self maxDim];
                itemSize.width = [self maxDim] / heightRatio;
            }

            if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
                maxItemHeight = MAX(maxItemHeight, itemSize.height);

                UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                [itemAttrs setFrame:CGRectMake(xOffset, yOffset, itemSize.width, itemSize.height)];
                [itemAttrs setZIndex:rowCount - row];

                if (didFinish || xOffset + itemSize.width >= [self collectionViewContentSize].width - [self sectionInsets].right) {
                    didFinish = YES;
                    [itemAttrs setAlpha:0];
                    [itemAttrs setHidden:YES];
                } else {
                    [itemAttrs setAlpha:1];
                    [itemAttrs setHidden:NO];
                }

                if (rotation) {
                    [itemAttrs setTransform:CGAffineTransformMakeRotation(rotation)];
                } else {
                    [itemAttrs setTransform:CGAffineTransformIdentity];
                }

                [_shelfCache addObject:itemAttrs];

                if (didFinish) {
                    // These pages are invisible, so place them randomly throughout the line
                    // of visible pages so that they animate interestingly to/from grid layout
                    CGFloat allowedWidth = [self collectionViewContentSize].width - [self sectionInsets].left - [self sectionInsets].right;
                    xOffset = rand() % (int)(allowedWidth - itemSize.width);
                } else {
                    xOffset += _pageSpacing;
                }
            }
        }

        yOffset += maxItemHeight + _sectionInsets.bottom;
    }

    _contentHeight = yOffset;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // TODO: the cache could be sorted by y value, and we can use this to binary search for the items in the rect
    return [_shelfCache filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable obj, NSDictionary<NSString *, id> *_Nullable bindings) {
        return CGRectIntersectsRect([obj frame], rect) && ![obj isHidden];
    }]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    for (UICollectionViewLayoutAttributes *attrs in _shelfCache) {
        if ([attrs representedElementCategory] == UICollectionElementCategorySupplementaryView && [[attrs indexPath] isEqual:indexPath]) {
            return attrs;
        }
    }
    return nil;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    for (UICollectionViewLayoutAttributes *attrs in _shelfCache) {
        if ([attrs representedElementCategory] == UICollectionElementCategoryCell && [[attrs indexPath] isEqual:indexPath]) {
            return attrs;
        }
    }

    return nil;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if ([self targetIndexPath]) {
        UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[self targetIndexPath]];

        attrs = attrs ?: [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

        CGFloat const inset = -[[self collectionView] safeAreaInsets].top;
        CGFloat const screenHeight = CGRectGetHeight([[self collectionView] bounds]);
        CGSize const size = [self collectionViewContentSize];
        CGFloat targetY = attrs.frame.origin.y + inset;
        targetY = targetY < size.height - screenHeight ? targetY : size.height - screenHeight;
        targetY = targetY < inset ? inset : targetY;

        return CGPointMake(0, targetY);
    }

    return proposedContentOffset;
}

@end
