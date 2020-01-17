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

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *pageCache;

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
        _pageCache = [NSMutableArray array];
        _fitWidth = YES;
        _direction = MMPageLayoutVertical;
    }
    return self;
}

- (instancetype)initWithSection:(NSInteger)section
{
    if (self = [super initWithSection:section]) {
        _pageCache = [NSMutableArray array];
        _fitWidth = YES;
        _direction = MMPageLayoutVertical;
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
    return _direction == MMPageLayoutHorizontal;
}

- (BOOL)bounceVertical
{
    return _direction == MMPageLayoutVertical;
}

#pragma mark - UICollectionViewLayout

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = [super collectionViewContentSize];
    UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

    if (_direction == MMPageLayoutVertical) {
        return CGSizeMake(MAX(_sectionWidth, contentSize.width) + insets.left + insets.right, _sectionHeight);
    } else {
        return CGSizeMake(MAX(_sectionWidth, contentSize.width), _sectionHeight + insets.top + insets.bottom);
    }
}

- (void)invalidateLayout
{
    [super invalidateLayout];

    [_pageCache removeAllObjects];
}

- (void)prepareLayout
{
    [super prepareLayout];

    if (_direction == MMPageLayoutVertical) {
        UICollectionViewLayoutAttributes *header = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self section]]];
        _sectionOffset = CGRectGetMinY([header frame]);
    } else {
        _sectionOffset = 0;
    }

    _sectionWidth = 0;

    UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

    CGFloat maxDim;

    if (_direction == MMPageLayoutVertical) {
        maxDim = CGRectGetWidth([[self collectionView] bounds]) - insets.left - insets.right;
    } else {
        maxDim = CGRectGetHeight([[self collectionView] bounds]) - insets.top - insets.bottom;
    }

    CGFloat const kMaxDim = maxDim;

    CGFloat offset = 0;
    NSInteger const kItemCount = [[self collectionView] numberOfItemsInSection:[self section]];
    CGFloat maxActualItemDim = kMaxDim;
    CGSize headerSize = [self defaultHeaderSize];

    // Calculate the header section size, if any
    if ([[self delegate] respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        headerSize = [[self delegate] collectionView:[self collectionView] layout:self referenceSizeForHeaderInSection:[self section]];
    }

    if (!CGSizeEqualToSize(headerSize, CGSizeZero)) {
        UICollectionViewLayoutAttributes *headerAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self section]]];
        if (_direction == MMPageLayoutVertical) {
            [headerAttrs setFrame:CGRectMake(insets.left, offset, headerSize.width, headerSize.height)];
        } else {
            [headerAttrs setFrame:CGRectMake(offset, insets.top, headerSize.width, headerSize.height)];
        }

        [_pageCache addObject:headerAttrs];


        if (_direction == MMPageLayoutVertical) {
            offset += headerSize.height;
        } else {
            offset += headerSize.width;
        }
    }

    if (_direction == MMPageLayoutVertical) {
        offset += [self sectionInsets].top;
    } else {
        offset += [self sectionInsets].left;
    }

    // Calculate the size of each row
    for (NSInteger pageIdx = 0; pageIdx < kItemCount; pageIdx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:pageIdx inSection:[self section]];
        id<MMShelfLayoutObject> object = [[self datasource] collectionView:[self collectionView] layout:self objectAtIndexPath:indexPath];

        CGSize idealSize = [object idealSize];
        CGFloat rotation = [object rotation];

        // scale the page so that if fits in screen when its fully rotated.
        // This is the screen-aligned box that contains our rotated page
        CGSize boundingSize;
        CGSize itemSize;

        if (_direction == MMPageLayoutVertical) {
            boundingSize = MMFitSizeToWidth(MMBoundingSizeFor(idealSize, rotation), kMaxDim, [self fitWidth]);

            // now we need to find the unrotated size of the page that
            // fits in the above box when its rotated.
            //
            // If the page is the exact same size as the screen, we rotate it
            // and then we have to shrink it so that the corners of the page
            // are always barely touching the screen edges.
            itemSize = CGSizeForInscribedWidth(idealSize.height / idealSize.width, boundingSize.width, rotation);
        } else {
            boundingSize = MMFitSizeToHeight(MMBoundingSizeFor(idealSize, rotation), kMaxDim, [self fitWidth]);
            itemSize = CGSizeForInscribedHeight(idealSize.height / idealSize.width, boundingSize.height, rotation);
        }

        // Next, scale the page to account for our delegate's pinch-to-zoom.
        CGFloat scale = 1;
        if ([[self delegate] respondsToSelector:@selector(collectionView:layout:zoomScaleForIndexPath:)]) {
            scale = [[self delegate] collectionView:[self collectionView] layout:self zoomScaleForIndexPath:indexPath];
        }

        CGFloat diff;

        if (_direction == MMPageLayoutVertical) {
            diff = (kMaxDim - itemSize.width) / 2.0 * scale + insets.left;
        } else {
            diff = (kMaxDim - itemSize.height) / 2.0 * scale + insets.top;
        }

        if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
            // set all the attributes
            CGFloat altDiff;
            UICollectionViewLayoutAttributes *itemAttrs;
            CGRect frame;

            if (_direction == MMPageLayoutVertical) {
                altDiff = (itemSize.height - boundingSize.height) / 2.0 * scale;
                itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:pageIdx inSection:[self section]]];
                frame = CGRectMake(diff, offset - altDiff, itemSize.width, itemSize.height);
            } else {
                altDiff = (itemSize.width - boundingSize.width) / 2.0 * scale;
                itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:pageIdx inSection:[self section]]];
                frame = CGRectMake(offset - altDiff, diff, itemSize.width, itemSize.height);
            }

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

            if (_direction == MMPageLayoutVertical) {
                offset += boundingSize.height * scale;
            } else {
                offset += boundingSize.width * scale;
            }

            [_pageCache addObject:itemAttrs];

            if (_direction == MMPageLayoutVertical) {
                maxActualItemDim = MAX(maxActualItemDim, boundingSize.width * scale);
                _sectionWidth = MAX(_sectionWidth, kMaxDim * scale);
            } else {
                maxActualItemDim = MAX(maxActualItemDim, boundingSize.height * scale);
                _sectionHeight = MAX(_sectionHeight, kMaxDim * scale);
            }
        }
    }

    if (_direction == MMPageLayoutVertical) {
        if (maxActualItemDim < _sectionWidth) {
            // all of our pages were smaller than the width of our collection view.
            // center these items in the available space left over. This lets us
            // keep the collection view content size the same as its width for as
            // long as possible when zooming collections of smaller pages
            CGFloat leftBump = (_sectionWidth - maxActualItemDim) / 2;

            for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
                CGPoint center = [attrs center];
                center.x -= leftBump;
                [attrs setCenter:center];
            }

            _sectionWidth = maxActualItemDim;
        }
    } else {
        if (maxActualItemDim < _sectionHeight) {
            // all of our pages were smaller than the width of our collection view.
            // center these items in the available space left over. This lets us
            // keep the collection view content size the same as its width for as
            // long as possible when zooming collections of smaller pages
            CGFloat topBump = (_sectionHeight - maxActualItemDim) / 2;

            for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
                CGPoint center = [attrs center];
                center.y -= topBump;
                [attrs setCenter:center];
            }

            _sectionHeight = maxActualItemDim;
        }
    }

    if (_direction == MMPageLayoutVertical) {
        offset += [self sectionInsets].bottom;
        _sectionHeight = offset;
    } else {
        offset += [self sectionInsets].left;
        _sectionWidth = offset;
    }
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [_pageCache filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable obj, NSDictionary<NSString *, id> *_Nullable bindings) {
        return CGRectIntersectsRect([obj frame], rect);
    }]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
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
        for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
            if ([attrs representedElementCategory] == UICollectionElementCategoryCell && [[attrs indexPath] isEqual:indexPath]) {
                return attrs;
            }
        }
    }

    return [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if ([self gestureRecognizer]) {
        UICollectionViewCell *cell = [[self collectionView] cellForItemAtIndexPath:[self targetIndexPath]];
        UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

        [cell applyLayoutAttributes:attrs];

        CGPoint gestureLocation = [[self gestureRecognizer] locationInView:[[self collectionView] superview]];
        gestureLocation.x -= [[self collectionView] frame].origin.x;
        gestureLocation.y -= [[self collectionView] frame].origin.y;

        CGPoint locInContent;
        locInContent.x = [self collectionViewContentSize].width * _targetOffset.x;
        locInContent.y = [self collectionViewContentSize].height * _targetOffset.y;

        locInContent.x -= gestureLocation.x;
        locInContent.y -= gestureLocation.y;

        // now that our content is aligned with our gesture,
        // clamp it to the edges of our content
        CGSize contentSize = [self collectionViewContentSize];
        CGSize viewSize = [[self collectionView] bounds].size;
        UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

        locInContent.x = MAX(0, MIN(contentSize.width - viewSize.width, locInContent.x));
        locInContent.y = MAX(-insets.top, MIN(contentSize.height - viewSize.height, locInContent.y));

        return locInContent;
    } else if ([self direction] == MMPageLayoutHorizontal) {
        if ([self targetIndexPath]) {
            if ([[self targetIndexPath] row] == 0) {
                UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

                return CGPointMake(CGRectGetMinX([attrs frame]), 0);
            } else {
                UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

                CGRect itemFrame = [attrs frame];
                CGFloat diff = MAX(0, (CGRectGetWidth([[self collectionView] bounds]) - CGRectGetWidth(itemFrame)) / 2.0);

                return CGPointMake(CGRectGetMinX(itemFrame) - diff, 0);
            }
        }
    } else {
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
    }

    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}

@end
