//
//  MMPageLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageLayout.h"
#import "Constants.h"


@interface MMPageLayoutAttributes : UICollectionViewLayoutAttributes

@property(nonatomic, assign) CGSize boundingSize;
@property(nonatomic, assign) CGFloat scale;

@end


@implementation MMPageLayoutAttributes

@end


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

- (MMPageLayoutAttributes *)layoutPage:(id<MMShelfLayoutObject>)object atOffset:(CGFloat const)offset forIndexPath:(NSIndexPath *const)indexPath kMaxDim:(CGFloat const)kMaxDim
{
    CGSize idealSize = [object idealSize];
    CGFloat rotation = [object rotation];
    UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

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

    MMPageLayoutAttributes *itemAttrs;

    if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
        // set all the attributes
        CGFloat altDiff;
        CGRect frame;

        if (_direction == MMPageLayoutVertical) {
            altDiff = (itemSize.height - boundingSize.height) / 2.0 * scale;
            itemAttrs = [MMPageLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            frame = CGRectMake(diff, offset - altDiff, itemSize.width, itemSize.height);
        } else {
            altDiff = (itemSize.width - boundingSize.width) / 2.0 * scale;
            itemAttrs = [MMPageLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
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

        [itemAttrs setBoundingSize:boundingSize];
        [itemAttrs setScale:scale];
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
    }

    return itemAttrs;
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
    _sectionHeight = 0;

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
    CGFloat scaledMaxDim = kMaxDim;
    CGSize headerSize = [self defaultHeaderSize];

    // Calculate the header section size, if any
    if ([[self delegate] respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        headerSize = [[self delegate] collectionView:[self collectionView] layout:self referenceSizeForHeaderInSection:[self section]];
    }

    // Layout the header, if any
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

    // Layout each page
    for (NSInteger pageIdx = 0; pageIdx < kItemCount; pageIdx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:pageIdx inSection:[self section]];
        id<MMShelfLayoutObject> object = [[self datasource] collectionView:[self collectionView] layout:self objectAtIndexPath:indexPath];
        MMPageLayoutAttributes *itemAttrs = [self layoutPage:object atOffset:offset forIndexPath:indexPath kMaxDim:kMaxDim];

        if (itemAttrs) {
            CGSize const boundingSize = [itemAttrs boundingSize];
            CGFloat const scale = [itemAttrs scale];

            [_pageCache addObject:itemAttrs];

            // update our offset to account for this page
            if (_direction == MMPageLayoutVertical) {
                offset += boundingSize.height * scale;
            } else {
                offset += boundingSize.width * scale;
            }

            // and track our max orthogonal dimension as well
            if (_direction == MMPageLayoutVertical) {
                scaledMaxDim = MAX(scaledMaxDim, boundingSize.width * scale);
                _sectionWidth = MAX(_sectionWidth, kMaxDim * scale);
            } else {
                scaledMaxDim = MAX(scaledMaxDim, boundingSize.height * scale);
                _sectionHeight = MAX(_sectionHeight, kMaxDim * scale);
            }
        }
    }

    // Determine the max size in each dimension for this layout
    if (_direction == MMPageLayoutVertical) {
        if (scaledMaxDim < _sectionWidth) {
            // all of our pages were smaller than the width of our collection view.
            // center these items in the available space left over. This lets us
            // keep the collection view content size the same as its width for as
            // long as possible when zooming collections of smaller pages
            CGFloat leftBump = (_sectionWidth - scaledMaxDim) / 2;

            for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
                CGPoint center = [attrs center];
                center.x -= leftBump;
                [attrs setCenter:center];
            }

            _sectionWidth = scaledMaxDim;
        }
    } else if (_direction == MMPageLayoutHorizontal) {
        if (scaledMaxDim < _sectionHeight) {
            // all of our pages were smaller than the width of our collection view.
            // center these items in the available space left over. This lets us
            // keep the collection view content size the same as its width for as
            // long as possible when zooming collections of smaller pages
            CGFloat topBump = (_sectionHeight - scaledMaxDim) / 2;

            for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
                CGPoint center = [attrs center];
                center.y -= topBump;
                [attrs setCenter:center];
            }

            _sectionHeight = scaledMaxDim;
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

#pragma mark - Fetch Attributes

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

#pragma mark - Content Offset

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    CGSize contentSize = [self collectionViewContentSize];
    CGSize viewSize = [[self collectionView] bounds].size;
    UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

    if ([self gestureRecognizer]) {
        // the user is pinching to zoom the page. calculate an offset for our content
        // that will keep the pinch gesture in the same location of the zoomed page.
        // This method is called during zoom because the collection view is constantly
        // resetting its layout to a new page layout, so it transitions from page layout
        // to page layout, and uses this method to keep the offset where it needs to be
        CGPoint gestureLocation = [[self gestureRecognizer] locationInView:[[self collectionView] superview]];
        gestureLocation.x -= [[self collectionView] frame].origin.x;
        gestureLocation.y -= [[self collectionView] frame].origin.y;

        CGPoint locInContent;
        // _targetPercentOffset is the % of our contentSize that should align to our gesture
        locInContent.x = [self collectionViewContentSize].width * _targetPercentOffset.x;
        locInContent.y = [self collectionViewContentSize].height * _targetPercentOffset.y;

        // so remove the gesture's offset to adjust that % of content size to our top/left of the screen
        locInContent.x -= gestureLocation.x;
        locInContent.y -= gestureLocation.y;

        // now that our content is aligned with our gesture,
        // clamp it to the edges of our content
        locInContent.x = MAX(-insets.left, MIN(contentSize.width - viewSize.width, locInContent.x));
        locInContent.y = MAX(-insets.top, MIN(contentSize.height - viewSize.height, locInContent.y));

        return locInContent;
    } else if ([self direction] == MMPageLayoutHorizontal) {
        if ([self targetIndexPath]) {
            CGPoint locInContent;

            if ([[self targetIndexPath] row] == 0) {
                // for the first page, align it to the left of the screen
                UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

                locInContent = CGPointMake(CGRectGetMinX([attrs frame]), 0);
            } else {
                // for all other pages, align them to the center of the screen
                UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

                CGRect itemFrame = [attrs frame];
                CGFloat diff = MAX(0, (CGRectGetWidth([[self collectionView] bounds]) - CGRectGetWidth(itemFrame)) / 2.0);

                locInContent = CGPointMake(CGRectGetMinX(itemFrame) - diff, 0);
            }

            // clamp the offset so that we're not over/under scrolling our content size
            locInContent.x = MAX(-insets.left, MIN(contentSize.width - viewSize.width, locInContent.x));

            return locInContent;
        }
    } else if ([self direction] == MMPageLayoutVertical) {
        if ([self targetIndexPath]) {
            CGPoint locInContent;

            if ([[self targetIndexPath] row] == 0) {
                // align the first page to the top of the screen
                UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

                locInContent = CGPointMake(0, CGRectGetMinY([attrs frame]));
            } else {
                // and align all other pages to the center of the screen
                UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[self targetIndexPath]];

                CGRect itemFrame = [attrs frame];
                CGFloat diff = MAX(0, (CGRectGetHeight([[self collectionView] bounds]) - CGRectGetHeight(itemFrame)) / 2.0);

                locInContent = CGPointMake(0, CGRectGetMinY(itemFrame) - diff);
            }

            // clamp the offset so that we're not over/under scrolling our content size
            locInContent.y = MAX(-insets.top, MIN(contentSize.height - viewSize.height, locInContent.y));

            return locInContent;
        }
    }

    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}

@end
