//
//  MMPageLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageLayout.h"
#import "Constants.h"


@interface MMPageLayout ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cache;

@end


@implementation MMPageLayout {
    CGFloat _sectionOffset;
    CGFloat _sectionHeight;
    CGFloat _sectionWidth;
}

@dynamic delegate;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _cache = [NSMutableArray array];
        _fitWidth = YES;
    }
    return self;
}

- (instancetype)initWithSection:(NSInteger)section
{
    if (self = [super initWithSection:section]) {
        _cache = [NSMutableArray array];
        _fitWidth = YES;
    }
    return self;
}

- (BOOL)isShelfLayout
{
    return NO;
}

- (BOOL)isGridLayout
{
    return NO;
}

- (BOOL)isPageLayout
{
    return YES;
}

- (BOOL)bounceHorizontal
{
    return NO;
}

#pragma mark - UICollectionViewLayout

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = [super collectionViewContentSize];

    return CGSizeMake(MAX(_sectionWidth, contentSize.width), _sectionHeight);
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
    _sectionWidth = 0;

    CGFloat const kMaxWidth = CGRectGetWidth([[self collectionView] bounds]);
    CGFloat yOffset = 0;
    NSInteger const kPageCount = [[self collectionView] numberOfItemsInSection:[self section]];
    CGFloat maxItemWidth = kMaxWidth;
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
    for (NSInteger pageIdx = 0; pageIdx < kPageCount; pageIdx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:pageIdx inSection:[self section]];
        id<MMShelfLayoutObject> object = [[self datasource] collectionView:[self collectionView] layout:self objectAtIndexPath:indexPath];

        CGSize idealSize = [object idealSize];
        CGFloat rotation = [object rotation];

        // scale the page so that if fits in screen when its fully rotated.
        // This is the screen-aligned box that contains our rotated page
        CGSize boundingSize = MMFitSizeToWidth(MMBoundingSizeFor(idealSize, rotation), kMaxWidth, [self fitWidth]);
        // now we need to find the unrotated size of the page that
        // fits in the above box when its rotated.
        //
        // If the page is the exact same size as the screen, we rotate it
        // and then we have to shrink it so that the corners of the page
        // are always barely touching the screen edges.
        CGSize itemSize = CGSizeForInscribedWidth(idealSize.height / idealSize.width, boundingSize.width, rotation);

        // Next, scale the page to account for our delegate's pinch-to-zoom.
        CGFloat scale = 1;
        if ([[self delegate] respondsToSelector:@selector(collectionView:layout:zoomScaleForIndexPath:)]) {
            scale = [[self delegate] collectionView:[self collectionView] layout:self zoomScaleForIndexPath:indexPath];
        }

        CGFloat diff = (kMaxWidth - itemSize.width) / 2.0 * scale;

        if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
            // set all the attributes
            CGFloat yDiff = (itemSize.height - boundingSize.height) / 2.0 * scale;
            UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:pageIdx inSection:[self section]]];
            CGRect frame = CGRectMake(diff, yOffset - yDiff, itemSize.width, itemSize.height);

            // For forcing the UICollectionViewBug described below.
            // this doesn't need to be included, as a 180 degree
            // rotation will also do this, but forcing it will
            // help make sure our fix described below will always work
            frame.origin.x -= -0.00000000000011368683772161603;

            [itemAttrs setFrame:frame];

            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeTranslation(-itemSize.width / 2, -itemSize.height / 2), scale, scale), itemSize.width / 2, itemSize.height / 2);

            if (rotation) {
                transform = CGAffineTransformRotate(transform, rotation);
            }

            [itemAttrs setAlpha:1];
            [itemAttrs setHidden:NO];
            [itemAttrs setTransform:transform];

            {
                // This block is for the UICollectionViewBug, where if a frame of an item
                // has a tiny offset from a round pixel, then it might disappear from the
                // collection view altogether.
                // Filed at FB7415012
                CGFloat bumpX = [itemAttrs frame].origin.x - floor([itemAttrs frame].origin.x);
                CGFloat bumpY = [itemAttrs frame].origin.y - floor([itemAttrs frame].origin.y);

                [itemAttrs setCenter:CGPointMake([itemAttrs center].x - bumpX, [itemAttrs center].y - bumpY)];
            }

            yOffset += boundingSize.height * scale;

            [_cache addObject:itemAttrs];

            maxItemWidth = MAX(maxItemWidth, boundingSize.width * scale);
            _sectionWidth = MAX(_sectionWidth, kMaxWidth * scale);
        }
    }

    if (maxItemWidth < _sectionWidth) {
        // all of our pages were smaller than the width of our collection view.
        // center these items in the available space left over. This lets us
        // keep the collection view content size the same as its width for as
        // long as possible when zooming collections of smaller pages
        CGFloat leftBump = (_sectionWidth - maxItemWidth) / 2;

        for (UICollectionViewLayoutAttributes *attrs in _cache) {
            CGPoint center = [attrs center];
            center.x -= leftBump;
            [attrs setCenter:center];
        }

        _sectionWidth = maxItemWidth;
    }

    yOffset += [self sectionInsets].bottom;

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
