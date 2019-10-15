//
//  MMPageLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageLayout.h"


@interface MMPageLayout ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cache;

@end


@implementation MMPageLayout {
    CGFloat _sectionOffset;
    CGFloat _sectionHeight;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _cache = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithSection:(NSInteger)section
{
    if (self = [super initWithSection:section]) {
        _cache = [NSMutableArray array];
    }
    return self;
}

-(BOOL)isShelfLayout{
    return NO;
}

-(BOOL)isGridLayout{
    return NO;
}

-(BOOL)isPageLayout{
    return YES;
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

    UICollectionViewLayoutAttributes *header = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self section]]];
    _sectionOffset = CGRectGetMinY([header frame]);

    CGFloat maxWidth = CGRectGetWidth([[self collectionView] bounds]);
    CGFloat yOffset = 0;
    NSInteger rowCount = [[self collectionView] numberOfItemsInSection:[self section]];
    CGFloat maxItemHeight = 0;
    CGSize headerSize = [self defaultHeaderSize];

    // Calculate the header section size, if any
    if ([[self delegate] respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        headerSize = [[self delegate] collectionView:[self collectionView] layout:self referenceSizeForHeaderInSection:[self section]];
    }

    if (!CGSizeEqualToSize(headerSize, CGSizeZero)) {
        UICollectionViewLayoutAttributes *headerAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self section]]];
        [headerAttrs setFrame:CGRectMake(0, yOffset, headerSize.width, headerSize.height)];
        [_cache addObject:headerAttrs];

        yOffset += headerSize.height;
    }

    yOffset += [self sectionInsets].top;

    // Calculate the size of each row
    for (NSInteger row = 0; row < rowCount; row++) {
        CGSize itemSize = [self defaultItemSize];

        // scale up our default item size so that it fits the screen width
        itemSize.height = CGRectGetWidth([[self collectionView] bounds]) / itemSize.width * itemSize.height;
        itemSize.width = CGRectGetWidth([[self collectionView] bounds]);

        if ([[self delegate] respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
            itemSize = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:[self section]]];
        }

        CGFloat diff = (maxWidth - itemSize.width) / 2.0;

        if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
            // set all the attributes
            UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:[self section]]];
            [itemAttrs setFrame:CGRectMake(diff, yOffset, itemSize.width, itemSize.height)];

            [itemAttrs setAlpha:1];
            [itemAttrs setHidden:NO];

            yOffset += itemSize.height;

            [_cache addObject:itemAttrs];
        }
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

    return [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
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

    return [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if ([self targetIndexPath]) {
        if ([[self targetIndexPath] row] == 0) {
            UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

            return CGPointMake(0, CGRectGetMinY([attrs frame]));
        } else {
            UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

            CGRect itemFrame = [attrs frame];
            CGFloat diff = MAX(0, (CGRectGetHeight([[self collectionView] bounds]) - CGRectGetHeight(itemFrame)) / 2.0);

            return CGPointMake(0, CGRectGetMinY(itemFrame) - diff);
        }
    }

    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}

@end
