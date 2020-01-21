//
//  MMShelfLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMShelfLayout.h"
#import "Constants.h"


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
        _defaultHeaderHeight = 50;
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
        _defaultHeaderHeight = 50;
        _maxDim = 140;
    }
    return self;
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
    if ([_shelfCache count]) {
        // don't relayout if we haven't been invalidated.
        return;
    }

    CGFloat yOffset = 0;

    for (NSInteger section = 0; section < [[self collectionView] numberOfSections]; section++) {
        NSInteger rowCount = [[self collectionView] numberOfItemsInSection:section];
        CGFloat maxItemHeight = 0;
        CGFloat headerHeight = [self defaultHeaderHeight];

        // Calculate the header section size, if any
        if ([[self delegate] respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
            headerHeight = [[self delegate] collectionView:[self collectionView] layout:self heightForHeaderInSection:section];
        }

        if (headerHeight > 0) {
            UICollectionViewLayoutAttributes *headerAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
            [headerAttrs setFrame:CGRectMake(0, yOffset, CGRectGetWidth([[self collectionView] bounds]), headerHeight)];
            [_shelfCache addObject:headerAttrs];

            yOffset += headerHeight;
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

            // calculate the dimensions of each item so that it fits within itemSize
            if (itemSize.height <= itemSize.width && itemSize.width > [self maxDim]) {
                itemSize.height = [self maxDim] * heightRatio;
                itemSize.width = [self maxDim];
            } else if (itemSize.height >= itemSize.width && itemSize.height > [self maxDim]) {
                itemSize.height = [self maxDim];
                itemSize.width = [self maxDim] / heightRatio;
            }

            CGSize boundingSize = MMBoundingSizeFor(itemSize, rotation);

            maxItemHeight = MAX(maxItemHeight, boundingSize.height);

            UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            [itemAttrs setBounds:CGRectMake(0, 0, itemSize.width, itemSize.height)];
            [itemAttrs setZIndex:rowCount - row];
            [itemAttrs setCenter:CGPointMake(xOffset + itemSize.width / 2, yOffset + boundingSize.height / 2)];

            if (rotation) {
                [itemAttrs setTransform:CGAffineTransformMakeRotation(rotation)];
            } else {
                [itemAttrs setTransform:CGAffineTransformIdentity];
            }

            // we've finished our row if the item would step into our section inset area.
            // we need to || because our xOffset is going to be randomly distributed after
            // this item, and our inequality won't always be true after the first hidden item
            didFinish = didFinish || xOffset + itemSize.width >= [self collectionViewContentSize].width - [self sectionInsets].right;

            if (didFinish) {
                didFinish = YES;
                [itemAttrs setAlpha:0];
                [itemAttrs setHidden:YES];

                // These pages are invisible, so place them randomly throughout the line
                // of visible pages so that they animate interestingly to/from grid layout
                CGFloat allowedWidth = [self collectionViewContentSize].width - [self sectionInsets].left - [self sectionInsets].right;
                xOffset = rand() % (int)(allowedWidth - itemSize.width);
            } else {
                [itemAttrs setAlpha:1];
                [itemAttrs setHidden:NO];

                // this page is visible, so adjust spacing to align the next page in the list
                xOffset += _pageSpacing;
            }

            [_shelfCache addObject:itemAttrs];
        }

        yOffset += maxItemHeight + _sectionInsets.bottom;
    }

    _contentHeight = yOffset;
}

#pragma mark - Fetch Attributes

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // TODO: the cache could be sorted by center.y value, and we can use this to binary search for the items in the rect
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

#pragma mark - Content Offset

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if ([self targetIndexPath]) {
        // when pinching from grid to shelf view, we want to keep the visible document
        // in the middle of the shelf. this will calculate its offset within our content size
        // and then clamp it to our min/max allowed content offset
        UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[self targetIndexPath]];

        attrs = attrs ?: [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

        CGFloat const inset = -[[self collectionView] safeAreaInsets].top;
        CGFloat const screenHeight = CGRectGetHeight([[self collectionView] bounds]);
        CGSize const size = [self collectionViewContentSize];
        CGFloat targetY = attrs.frame.origin.y + inset;

        // clamp the target Y to our content size
        targetY = targetY < size.height - screenHeight ? targetY : size.height - screenHeight;
        targetY = targetY < inset ? inset : targetY;

        return CGPointMake(0, targetY);
    }

    return proposedContentOffset;
}

@end
