//
//  MMGridLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMGridLayout.h"


@interface MMGridLayout ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cache;

@end


@implementation MMGridLayout {
    CGFloat _sectionOffset;
    CGFloat _sectionHeight;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _cache = [NSMutableArray array];
        _itemMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

- (instancetype)initWithSection:(NSInteger)section
{
    if (self = [super init]) {
        _section = section;
        _cache = [NSMutableArray array];
        _itemMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

#pragma mark - Helpers

- (NSArray<UICollectionViewLayoutAttributes *> *)alignItemsInRow:(NSArray<UICollectionViewLayoutAttributes *> *)items maxItemHeight:(CGFloat)maxItemHeight rowWidth:(CGFloat)rowWidth yOffset:(CGFloat)yOffset stretchWidth:(BOOL)shouldStretch
{
    CGFloat widthDiff = [self collectionViewContentSize].width - rowWidth - [self sectionInsets].left - [self sectionInsets].right;
    CGFloat spacing = widthDiff / ([items count] - 1);

    [items enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *_Nonnull obj, NSUInteger index, BOOL *_Nonnull stop) {
        CGRect fr = [obj frame];

        fr.origin.x += [self sectionInsets].left;

        if (shouldStretch) {
            fr.origin.x += spacing * index;
        }

        fr.origin.y = yOffset + (maxItemHeight - CGRectGetHeight(fr)) / 2.0;

        [obj setFrame:fr];
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

    [_cache removeAllObjects];
}

- (void)prepareLayout
{
    [super prepareLayout];

    UICollectionViewLayoutAttributes *header = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:_section]];
    _sectionOffset = CGRectGetMinY([header frame]);


    CGFloat yOffset = 0;
    NSInteger rowCount = [[self collectionView] numberOfItemsInSection:_section];
    CGFloat maxItemHeight = 0;
    CGSize headerSize = [self defaultHeaderSize];

    // Calculate the header section size, if any
    if ([[self delegate] respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        headerSize = [[self delegate] collectionView:[self collectionView] layout:self referenceSizeForHeaderInSection:_section];
    }

    if (!CGSizeEqualToSize(headerSize, CGSizeZero)) {
        UICollectionViewLayoutAttributes *headerAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:_section]];
        [headerAttrs setFrame:CGRectMake(0, yOffset, headerSize.width, headerSize.height)];
        [_cache addObject:headerAttrs];

        yOffset += headerSize.height;
    }

    CGFloat xOffset = [self sectionInsets].left;
    yOffset += [self sectionInsets].top;

    NSMutableArray *attributesPerRow = [NSMutableArray array];
    CGFloat rowWidth = 0;
    CGFloat lastItemWidth = 0;

    // Calculate the size of each row
    for (NSInteger row = 0; row < rowCount; row++) {
        CGSize itemSize = [self defaultItemSize];

        if ([[self delegate] respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
            itemSize = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:_section]];
        }

        if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
            // can it fit on this row?
            if (xOffset + itemSize.width + [self sectionInsets].right > [self collectionViewContentSize].width) {
                // the row is done, remove the next item margins
                rowWidth -= _itemMargins.right + _itemMargins.left;
                // now realign all the items into their row so that they stretch full width
                [_cache addObjectsFromArray:[self alignItemsInRow:attributesPerRow maxItemHeight:maxItemHeight rowWidth:rowWidth yOffset:yOffset stretchWidth:YES]];
                [attributesPerRow removeAllObjects];

                yOffset += maxItemHeight + [self itemMargins].bottom + [self itemMargins].top;
                xOffset = [self sectionInsets].left;
                maxItemHeight = 0;
                rowWidth = 0;
            }

            maxItemHeight = MAX(maxItemHeight, itemSize.height);

            // set all the attributes
            UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:_section]];
            [itemAttrs setFrame:CGRectMake(rowWidth, 0, itemSize.width, itemSize.height)];
            [itemAttrs setZIndex:rowCount - row];
            [itemAttrs setAlpha:1];
            [itemAttrs setHidden:NO];

            lastItemWidth = itemSize.width;
            rowWidth += itemSize.width + _itemMargins.right + +_itemMargins.left;
            xOffset += itemSize.width + _itemMargins.right + +_itemMargins.left;

            [attributesPerRow addObject:itemAttrs];
        }
    }

    if ([attributesPerRow count]) {
        // we should stretch the last row if we're close to the edge anyways
        BOOL stretch = xOffset + lastItemWidth + [self sectionInsets].right > [self collectionViewContentSize].width;
        rowWidth -= _itemMargins.right + _itemMargins.left;

        [_cache addObjectsFromArray:[self alignItemsInRow:attributesPerRow maxItemHeight:maxItemHeight rowWidth:rowWidth yOffset:yOffset stretchWidth:stretch]];
    } else {
        // remove the top margin for the next row, since there is no next row
        yOffset -= [self itemMargins].top;
    }

    yOffset += maxItemHeight + [self sectionInsets].bottom;

    _sectionHeight = yOffset;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [_cache filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable obj, NSDictionary<NSString *, id> *_Nullable bindings) {
        return CGRectIntersectsRect([obj frame], rect);
    }]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        for (UICollectionViewLayoutAttributes *attrs in _cache) {
            if ([attrs representedElementCategory] == UICollectionElementCategorySupplementaryView && [[attrs indexPath] isEqual:indexPath]) {
                return attrs;
            }
        }
    }

    UICollectionViewLayoutAttributes *attrs = [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];

    CGRect fr = [attrs frame];

    fr.origin.y -= _sectionOffset;

    if ([indexPath section] > [self section]) {
        fr.origin.y += _sectionHeight;
    }

    [attrs setFrame:fr];
    [attrs setAlpha:0];

    return attrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        for (UICollectionViewLayoutAttributes *attrs in _cache) {
            if ([attrs representedElementCategory] == UICollectionElementCategoryCell && [[attrs indexPath] isEqual:indexPath]) {
                return attrs;
            }
        }
    }

    UICollectionViewLayoutAttributes *attrs = [super layoutAttributesForItemAtIndexPath:indexPath];

    CGRect fr = [attrs frame];

    fr.origin.y -= _sectionOffset;

    if ([indexPath section] > [self section]) {
        fr.origin.y += _sectionHeight;
    }

    [attrs setFrame:fr];
    [attrs setAlpha:0];

    return attrs;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if ([self targetIndexPath]) {
        CGPoint p = [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
        UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];
        CGRect itemFrame = [attrs frame];
        CGFloat diff = MAX(0, (CGRectGetHeight([[self collectionView] bounds]) - CGRectGetHeight(itemFrame)) / 2.0);

        p.y = MAX(0, CGRectGetMinY(itemFrame) - diff);

        return p;
    }

    return proposedContentOffset;
}

@end
