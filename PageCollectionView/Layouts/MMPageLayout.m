//
//  MMPageLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMPageLayout.h"
#import "Constants.h"
#import <MMToolbox/MMToolbox.h>


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
    // track the header height so that we know when the bounds are within/out of the headers
    CGFloat _headerHeight;
    // track the orthogonal dimention from scroll, so that when it changes we can invalidate the header attributes
    CGFloat _lastBoundsMinDim;
}

@dynamic delegate;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _pageCache = [NSMutableArray array];
        _fitWidth = YES;
        _direction = MMPageLayoutVertical;

        [self setSectionInsets:UIEdgeInsetsMake(10, 10, 40, 40)];
    }
    return self;
}

- (instancetype)initWithSection:(NSInteger)section
{
    if (self = [super initWithSection:section]) {
        _pageCache = [NSMutableArray array];
        _fitWidth = YES;
        _direction = MMPageLayoutVertical;

        [self setSectionInsets:UIEdgeInsetsMake(10, 10, 40, 40)];
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

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    // Check if our bounds have changed enough so that we need to re-align our headers
    // with the newly visible rect of the content
    CGFloat currMinBoundsDim = _lastBoundsMinDim;
    UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

    if (_direction == MMPageLayoutVertical && CGRectGetMinY(newBounds) < _headerHeight + insets.top) {
        currMinBoundsDim = CGRectGetMinX(newBounds);
    } else if (_direction == MMPageLayoutHorizontal && CGRectGetMinX(newBounds) < _headerHeight + insets.left) {
        currMinBoundsDim = CGRectGetMinY(newBounds);
    }

    if (currMinBoundsDim != _lastBoundsMinDim) {
        // if our header should move, then invalidate it
        _lastBoundsMinDim = currMinBoundsDim;

        [self invalidateLayoutWithContext:[self invalidationContextForBoundsChange:newBounds]];
    }

    // the above handles conditionally invalidatin the layout from this bounds change,
    // our [super] will handle invalidating the entire layout from the change
    return [super shouldInvalidateLayoutForBoundsChange:newBounds];
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds
{
    // The only thing we need to conditionally invalidate because of a bounds change is our header
    UICollectionViewLayoutInvalidationContext *context = [super invalidationContextForBoundsChange:newBounds];
    NSIndexPath *vHeaderPath = [NSIndexPath indexPathForRow:0 inSection:[self section]];
    NSIndexPath *hHeaderPath = [NSIndexPath indexPathForRow:1 inSection:[self section]];

    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:@[vHeaderPath, hHeaderPath]];

    return context;
}

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
    _sectionHeight = 0;

    CGRect const collectionViewBounds = [[self collectionView] bounds];
    UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

    CGFloat maxDim;

    if (_direction == MMPageLayoutVertical) {
        maxDim = CGRectGetWidth(collectionViewBounds) - insets.left - insets.right;
    } else {
        maxDim = CGRectGetHeight(collectionViewBounds) - insets.top - insets.bottom;
    }

    CGFloat const kMaxDim = maxDim;
    CGFloat offset = 0;
    NSInteger const kItemCount = [[self collectionView] numberOfItemsInSection:[self section]];
    CGFloat scaledMaxDim = kMaxDim;
    CGFloat headerHeight = [self defaultHeaderHeight];

    // Calculate the header section size, if any
    if ([[self delegate] respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
        headerHeight = [[self delegate] collectionView:[self collectionView] layout:self heightForHeaderInSection:[self section]];
    }

    _headerHeight = headerHeight;

    // track the location of the bounds in the direction orthogonal to the scroll
    if (_direction == MMPageLayoutVertical) {
        _lastBoundsMinDim = CGRectGetMinX(collectionViewBounds);
    } else if (_direction == MMPageLayoutHorizontal) {
        _lastBoundsMinDim = CGRectGetMinY(collectionViewBounds);
    }

    // Layout the header, if any
    if (headerHeight > 0) {
        UICollectionViewLayoutAttributes *vHeaderAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self section]]];
        UICollectionViewLayoutAttributes *hHeaderAttrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForRow:1 inSection:[self section]]];

        [vHeaderAttrs setBounds:CGRectMake(0, 0, CGRectGetWidth(collectionViewBounds) - insets.left - insets.right, headerHeight)];
        [vHeaderAttrs setCenter:CGPointMake(CGRectGetMidX(collectionViewBounds), headerHeight / 2)];
        [vHeaderAttrs setAlpha:_direction == MMPageLayoutVertical];

        [hHeaderAttrs setBounds:CGRectMake(0, 0, CGRectGetHeight(collectionViewBounds) - insets.top - insets.bottom, headerHeight)];
        [hHeaderAttrs setCenter:CGPointMake(headerHeight / 2, CGRectGetMidY(collectionViewBounds) + insets.top / 2)];
        [hHeaderAttrs setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
        [vHeaderAttrs setAlpha:_direction == MMPageLayoutHorizontal];

        [_pageCache addObject:vHeaderAttrs];
        [_pageCache addObject:hHeaderAttrs];

        offset += headerHeight;
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
        offset += [self sectionInsets].right;
        _sectionWidth = offset;
    }
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

    return itemAttrs;
}

#pragma mark - Fetch Attributes

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray<__kindof UICollectionViewLayoutAttributes *> *ret = [[_pageCache filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable obj, NSDictionary<NSString *, id> *_Nullable bindings) {
        return CGRectIntersectsRect([obj frame], rect);
    }]] mutableCopy];
    ;

    for (NSInteger index = 0; index < 2 && index < [ret count]; index++) {
        // update our headers
        if ([[[ret objectAtIndex:index] representedElementKind] isEqualToString:UICollectionElementKindSectionHeader]) {
            UICollectionViewLayoutAttributes *oldHeader = [ret objectAtIndex:index];
            UICollectionViewLayoutAttributes *newHeader = [self layoutAttributesForSupplementaryViewOfKind:[oldHeader representedElementKind] atIndexPath:[oldHeader indexPath]];

            [ret replaceObjectAtIndex:index withObject:newHeader];
        }
    }

    return ret;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        for (UICollectionViewLayoutAttributes *attrs in _pageCache) {
            if ([attrs representedElementCategory] == UICollectionElementCategorySupplementaryView && [[attrs indexPath] isEqual:indexPath]) {
                // center the attributes in the scrollable direction
                UICollectionViewLayoutAttributes *ret = [attrs copy];
                UIEdgeInsets insets = [[self collectionView] safeAreaInsets];

                if ([indexPath row] == 0) {
                    // asking for vertical header
                    if (_direction == MMPageLayoutVertical) {
                        CGFloat midDim = _lastBoundsMinDim + CGRectGetWidth([[self collectionView] bounds]) / 2;
                        [ret setCenter:CGPointMake(midDim + insets.left / 2 - insets.right / 2, _headerHeight / 2)];
                        [ret setAlpha:1];
                    } else {
                        [ret setAlpha:0];
                    }
                } else {
                    // asking for horizontal header
                    if (_direction == MMPageLayoutHorizontal) {
                        CGFloat midDim = _lastBoundsMinDim + CGRectGetHeight([[self collectionView] bounds]) / 2;
                        [ret setCenter:CGPointMake(_headerHeight / 2, midDim + insets.top / 2 - insets.bottom / 2)];
                        [ret setAlpha:1];
                    } else {
                        [ret setAlpha:0];
                    }
                }

                return ret;
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
    CGPoint ret = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);

    if ([self gestureRecognizer]) {
        // the user is pinching to zoom the page. calculate an offset for our content
        // that will keep the pinch gesture in the same location of the zoomed page.
        // This method is called during zoom because the collection view is constantly
        // resetting its layout to a new page layout, so it transitions from page layout
        // to page layout, and uses this method to keep the offset where it needs to be
        CGPoint outerOffset = [[self gestureRecognizer] locationInView:[[self collectionView] superview]];
        CGPoint startLocInContent;
        // _startingPercentOffset is the % of our contentSize that should align to our gesture
        // startLocInContent is the point in the content that is exactly under the gesture
        // when the gesture begins.
        startLocInContent.x = [self collectionViewContentSize].width * _startingPercentOffset.x;
        startLocInContent.y = [self collectionViewContentSize].height * _startingPercentOffset.y;

        CGPoint targetLocInContent = startLocInContent;

        // so remove the gesture's offset from the corner of the super view to the gesture,
        // as our contentOffset will need to be relative to that corner
        targetLocInContent.x -= outerOffset.x;
        targetLocInContent.y -= outerOffset.y;

        // If the user starts a pinch with two fingers, but then lifts a finger
        // the pinch gesture doesn't fail, but instead continues. By default,
        // the location of the gesture is the average of all touches, so this
        // makes the location jump around the screen as the user lifts and presses
        // down fingers mid-gesture. The MMPinchVelocityGestureRecognizer instead
        // handles this for us and returns a smooth locationInView: that accounts
        // for touches starting and stopping mid gesture. The `scaledAdjustment` property
        // is a CGPoint offset from teh gesture's location back to the initial
        // locationInView when the gesture first began. We can use this to
        // Adjust the content offset and keep the content under our fingers
        // throughout the pinch, even if the user 'walks' their fingers
        // down the screen resulting in a large scaledAdjustment.
        CGPoint scaledAdjustment = [[self gestureRecognizer] scaledAdjustment];

        targetLocInContent.x -= scaledAdjustment.x * MAX(1, [[self gestureRecognizer] scale]);
        targetLocInContent.y -= scaledAdjustment.y * MAX(1, [[self gestureRecognizer] scale]);

        // now that our content is aligned with our gesture,
        // clamp it to the edges of our content
        targetLocInContent.x = MAX(-insets.left, MIN(contentSize.width - viewSize.width, targetLocInContent.x));
        targetLocInContent.y = MAX(-insets.top, MIN(contentSize.height - viewSize.height, targetLocInContent.y));

        ret = targetLocInContent;
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

            ret = locInContent;
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

            ret = locInContent;
        }
    }

    if (ret.x == CGFLOAT_MAX) {
        ret = [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
    }

    CGRect bounds = [[self collectionView] bounds];
    bounds.origin = ret;

    // check if we need to invalidate headesr for this offset
    [self shouldInvalidateLayoutForBoundsChange:bounds];

    return ret;
}

@end
