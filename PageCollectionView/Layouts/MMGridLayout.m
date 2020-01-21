//
//  MMGridLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMGridLayout.h"
#import "Constants.h"


@interface MMGridLayout ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *gridCache;

@end


@implementation MMGridLayout {
    CGFloat _sectionOffset;
    CGFloat _sectionHeight;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _gridCache = [NSMutableArray array];
        _itemSpacing = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

- (instancetype)initWithSection:(NSInteger)section
{
    if (self = [super init]) {
        _section = section;
        _gridCache = [NSMutableArray array];
        _itemSpacing = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

#pragma mark - Helpers

- (NSArray<UICollectionViewLayoutAttributes *> *)alignItemsInRow:(NSArray<UICollectionViewLayoutAttributes *> *)items maxItemHeight:(CGFloat)maxItemHeight rowWidth:(CGFloat)rowWidth yOffset:(CGFloat)yOffset stretchWidth:(BOOL)shouldStretch
{
    CGFloat widthDiff = [self collectionViewContentSize].width - rowWidth - [self sectionInsets].left - [self sectionInsets].right;
    CGFloat spacing = [items count] > 1 ? widthDiff / ([items count] - 1) : 0;
    yOffset += maxItemHeight / 2.0; // so that the yoffset is based on the center instead of the top

    [items enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *_Nonnull obj, NSUInteger index, BOOL *_Nonnull stop) {
        CGPoint center = [obj center];

        center.x += [self sectionInsets].left;

        if (shouldStretch) {
            center.x += spacing * index;
        }

        center.y = yOffset;

        [obj setCenter:center];
    }];

    return items;
}

#pragma mark - UICollectionViewLayout

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = [super collectionViewContentSize];

    return CGSizeMake(contentSize.width, _sectionHeight);
}

- (void)invalidateLayout
{
    [super invalidateLayout];

    [_gridCache removeAllObjects];
}

- (void)prepareLayout
{
    [super prepareLayout];

    // Call [super] to get the attributes of our header in shelf mode. This will give us our section offset
    // in shelf mode, which we'll use to adjust all other items so that our grid section will appear at 0,0
    UICollectionViewLayoutAttributes *header = [super layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:_section]];
    _sectionOffset = CGRectGetMinY([header frame]);


    CGFloat yOffset = 0;
    NSInteger pageCount = [[self collectionView] numberOfItemsInSection:_section];
    CGFloat maxItemHeight = 0;
    CGFloat headerHeight = [self defaultHeaderHeight];

    // Calculate the header section size, if any
    if ([[self delegate] respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
        headerHeight = [[self delegate] collectionView:[self collectionView] layout:self heightForHeaderInSection:_section];
    }

    if (headerHeight > 0) {
        UICollectionViewLayoutAttributes *headerAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:_section]];
        [headerAttrs setFrame:CGRectMake(0, yOffset, CGRectGetWidth([[self collectionView] bounds]), headerHeight)];
        [_gridCache addObject:headerAttrs];

        yOffset += headerHeight;
    }

    CGFloat xOffset = [self sectionInsets].left;
    yOffset += [self sectionInsets].top;

    // a running list of all item attributes in the calculated row
    NSMutableArray *attributesPerRow = [NSMutableArray array];
    // track each rowWidth so that we can center all of the items in the row for equal left/right margins
    CGFloat rowWidth = 0;
    // track the row's last item's width, so that on our very last row we can see if we're within ~ 1 item from the edge
    CGFloat lastItemWidth = 0;

    // Calculate the size of each row
    for (NSInteger pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:pageIndex inSection:[self section]];
        id<MMShelfLayoutObject> object = [[self datasource] collectionView:[self collectionView] layout:self objectAtIndexPath:indexPath];
        CGFloat rotation = [object rotation];
        CGSize idealSize = MMFitSizeToWidth([object idealSize], [self maxDim], NO);
        CGSize boundingSize = MMBoundingSizeFor(idealSize, rotation);

        idealSize = MMFitSizeToWidth(idealSize, [self maxDim], NO);

        // can it fit on this row?
        if (xOffset + boundingSize.width + [self sectionInsets].right > [self collectionViewContentSize].width) {
            // the row is done, remove the next item spacing. the item spacing do not sum with the sectionInsets,
            // so the right+left spacing are added after every item to separate it from the following item. but there
            // is no following item, so remove those trailing margins.
            rowWidth -= _itemSpacing.right + _itemSpacing.left;
            // now realign all the items into their row so that they stretch full width
            [_gridCache addObjectsFromArray:[self alignItemsInRow:attributesPerRow maxItemHeight:maxItemHeight rowWidth:rowWidth yOffset:yOffset stretchWidth:YES]];
            [attributesPerRow removeAllObjects];

            yOffset += maxItemHeight + [self itemSpacing].bottom + [self itemSpacing].top;
            xOffset = [self sectionInsets].left;
            maxItemHeight = 0;
            rowWidth = 0;
        }

        // track this row's tallest item, so we can vertically center them all when the row is done
        maxItemHeight = MAX(maxItemHeight, boundingSize.height);

        // set all the attributes
        UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        [itemAttrs setBounds:CGRectMake(0, 0, idealSize.width, idealSize.height)];
        [itemAttrs setCenter:CGPointMake(rowWidth + boundingSize.width / 2, 0)];
        [itemAttrs setZIndex:pageCount - pageIndex];
        [itemAttrs setAlpha:1];
        [itemAttrs setHidden:NO];

        lastItemWidth = boundingSize.width;
        rowWidth += boundingSize.width + _itemSpacing.right + _itemSpacing.left;
        xOffset += boundingSize.width + _itemSpacing.right + _itemSpacing.left;

        if (rotation) {
            [itemAttrs setTransform:CGAffineTransformMakeRotation(rotation)];
        } else {
            [itemAttrs setTransform:CGAffineTransformIdentity];
        }

        [attributesPerRow addObject:itemAttrs];
    }

    if ([attributesPerRow count]) {
        // we should stretch the last row if we're close to the edge anyways
        BOOL stretch = xOffset + lastItemWidth + [self sectionInsets].right > [self collectionViewContentSize].width;
        rowWidth -= _itemSpacing.right + _itemSpacing.left;

        [_gridCache addObjectsFromArray:[self alignItemsInRow:attributesPerRow maxItemHeight:maxItemHeight rowWidth:rowWidth yOffset:yOffset stretchWidth:stretch]];
    } else {
        // remove the top margin for the next row, since there is no next row
        yOffset -= [self itemSpacing].top;
    }

    yOffset += maxItemHeight + [self sectionInsets].bottom;

    _sectionHeight = yOffset;
}

#pragma mark - Fetch Attributes

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [_gridCache filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable obj, NSDictionary<NSString *, id> *_Nullable bindings) {
        return CGRectIntersectsRect([obj frame], rect);
    }]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        for (UICollectionViewLayoutAttributes *attrs in _gridCache) {
            if ([attrs representedElementCategory] == UICollectionElementCategorySupplementaryView && [[attrs indexPath] isEqual:indexPath]) {
                return attrs;
            }
        }
    }

    UICollectionViewLayoutAttributes *attrs = [[super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath] copy];

    CGPoint center = [attrs center];

    center.y -= _sectionOffset;

    if ([indexPath section] > [self section]) {
        center.y += _sectionHeight;
    }

    [attrs setCenter:center];
    [attrs setAlpha:0];

    return attrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        for (UICollectionViewLayoutAttributes *attrs in _gridCache) {
            if ([attrs representedElementCategory] == UICollectionElementCategoryCell && [[attrs indexPath] isEqual:indexPath]) {
                return attrs;
            }
        }
    }

    // always [copy] from our [super] so that we don't accidentally modify our superclass's cached attributes
    UICollectionViewLayoutAttributes *attrs = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];

    CGPoint center = [attrs center];

    // adjust any non-visible sections to be further above or below our section
    // so that they animate nicely offscreen as we transition from shelf->grid
    center.y -= _sectionOffset;

    if ([indexPath section] > [self section]) {
        center.y += _sectionHeight;
    }

    [attrs setCenter:center];
    [attrs setAlpha:0];

    return attrs;
}

#pragma mark - Content Offset

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if ([self targetIndexPath]) {
        // when pinching from PageLayout, we'd like to focus the grid view so that
        // the page is centered in the view. To do that, calculate that target page's
        // offset within our content, and return a content offset that will align
        // with the middle of the screen
        CGPoint p = [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
        UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];
        CGRect itemFrame = [attrs frame];
        CGFloat diff = MAX(0, (CGRectGetHeight([[self collectionView] bounds]) - CGRectGetHeight(itemFrame)) / 2.0);
        CGFloat const inset = [[self collectionView] safeAreaInsets].top;
        CGSize contentSize = [self collectionViewContentSize];
        CGSize viewSize = [[self collectionView] bounds].size;

        p.y = MAX(-inset, MIN(contentSize.height - viewSize.height, CGRectGetMinY(itemFrame) - diff - inset));

        return p;
    }

    return proposedContentOffset;
}

@end
