//
//  MMGridLayout.m
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMGridLayout.h"
#import "MMLayoutAttributeCache.h"
#import "Constants.h"

NSInteger const kAnimationBufferSpace = 200;


@interface MMGridLayout ()

@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *gridCache;

@end


@implementation MMGridLayout {
    // the content size height of this grid
    CGFloat _sectionHeight;
    // the contentOffset.y to use during a transition either into/out of this layout
    CGFloat _yOffsetForTransition;
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

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForTransition
{
    // The only thing we need to conditionally invalidate because of a bounds change is our header
    UICollectionViewLayoutInvalidationContext *context = [[UICollectionViewLayoutInvalidationContext alloc] init];
    NSInteger sectionCount = [[self collectionView] numberOfSections];
    NSMutableArray<NSIndexPath *> *headers = [NSMutableArray array];
    NSMutableArray<NSIndexPath *> *items = [NSMutableArray array];
    for (NSInteger section = 0; section < sectionCount; section++) {
        MMLayoutAttributeCache *sectionCache = [self shelfAttributesForSection:section];

        [headers addObject:[NSIndexPath indexPathForRow:0 inSection:section]];
        [[sectionCache visibleItems] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [items addObject:[obj indexPath]];
        }];
    }

    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:headers];
    [context invalidateItemsAtIndexPaths:items];

    return context;
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
    UICollectionViewLayoutAttributes *headerAttrs = [[super layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:_section]] copy];
    CGRect headerFrame = [headerAttrs frame];

    CGFloat yOffset = 0;
    NSInteger pageCount = [[self collectionView] numberOfItemsInSection:_section];
    CGFloat maxItemHeight = 0;
    CGFloat headerHeight = CGRectGetHeight(headerFrame);

    if (headerHeight > 0) {
        headerFrame.origin.y = yOffset;
        [headerAttrs setFrame:headerFrame];

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
        idealSize = MMFitSizeToHeight(idealSize, [self maxDim] * 1.5, NO);
        CGSize boundingSize = MMBoundingSizeFor(idealSize, rotation);

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

#pragma mark - Transitions

- (void)prepareForTransitionToLayout:(UICollectionViewLayout *)newLayout
{
    [super prepareForTransitionToLayout:newLayout];

    // transition from grid view /to/ another layout, or scrolling within grid view
    _yOffsetForTransition = [[self collectionView] contentOffset].y;

    // invalidate all of the sections after our current section
    [self invalidateLayoutWithContext:[self invalidationContextForTransition]];
}

- (void)prepareForTransitionFromLayout:(UICollectionViewLayout *)oldLayout
{
    [super prepareForTransitionFromLayout:oldLayout];

    // transition from shelf view to grid view. When moving into the grid view,
    // the grid is always displayed at the very top of our content. if we ever
    // change to open to mid-grid from the shelf, then this will need to
    // compensate for that.
    _yOffsetForTransition = 0;

    // invalidate all of the sections after our current section
    [self invalidateLayoutWithContext:[self invalidationContextForTransition]];
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
    UICollectionViewLayoutAttributes *attrs = [[super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath] copy];

    [self adjustLayoutAttributesForTransition:attrs];

    if ([indexPath section] == [self section]) {
        [attrs setAlpha:1];
    } else {
        [attrs setAlpha:0];
    }

    return attrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == [self section]) {
        MMLayoutAttributeCache *sectionAttributes = [self shelfAttributesForSection:[self section]];

        for (UICollectionViewLayoutAttributes *attrs in _gridCache) {
            if ([attrs representedElementCategory] == UICollectionElementCategoryCell && [[attrs indexPath] isEqual:indexPath]) {
                if (_yOffsetForTransition > CGRectGetHeight([sectionAttributes frame]) && CGRectGetMaxY([attrs frame]) < _yOffsetForTransition) {
                    // if we're in a transition from grid view, our content offset is larger than 0.
                    // and if the page's frames are offscreen above our starting offset, then don't
                    // load our grid layout, instead, load and adjust the shelf layout below
                    break;
                }

                return attrs;
            }
        }
    }

    // always [copy] from our [super] so that we don't accidentally modify our superclass's cached attributes
    UICollectionViewLayoutAttributes *attrs = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];

    [self adjustLayoutAttributesForTransition:attrs];

    if ([indexPath section] == [self section]) {
        [attrs setAlpha:1];
    } else {
        [attrs setAlpha:0];
    }

    return attrs;
}

// Accepts shelf-relative attributs and adjusts them for the current transition
// offset target _yOffsetForTransition so that the attributes will animate
// into the new layout from just outside the visible screen area.
- (void)adjustLayoutAttributesForTransition:(UICollectionViewLayoutAttributes *)attrs
{
    // The following attributes should only be requested when transitioning to/from
    // this layout. The [prepareForTransitionTo/FromLayout:] methods invalidate these
    // elements, which will cause their attributes to be updated just in time for
    // the transition. Otherwise all of these elements are offscreen and invisible
    CGPoint center = [attrs center];
    MMLayoutAttributeCache *sectionAttributes = [self shelfAttributesForSection:[self section]];

    if ([[attrs indexPath] section] <= [self section]) {
        // for all sections that are before our grid, we can align those sections
        // as if they've shifted straight up from the top of our grid
        center.y -= CGRectGetMinY([sectionAttributes frame]);
        center.y += MAX(0, _yOffsetForTransition - CGRectGetHeight([sectionAttributes frame]) - kAnimationBufferSpace);
    } else if ([[attrs indexPath] section] > [self section]) {
        // for all sections after our grid, the goal is to have them pinch to/from
        // immediatley after the screen, regardless of our scroll position. To do
        // that, we invalidate all headers/items as the view scrolls so that they're
        // continually layout right after the end of the screen, and then in the same
        // layout as the shelf. this way, the transition will have them slide up
        // direction from the bottom edge of the screen
        CGFloat diff = CGRectGetMinY([attrs frame]) - CGRectGetMinY([sectionAttributes frame]);

        // start at the correct target offset for the grid view
        center.y = _yOffsetForTransition;
        // move to the bottom of the screen
        center.y += CGRectGetHeight([[self collectionView] bounds]);
        // adjust the header to be in its correct offset to its neighbors
        center.y += diff;
        // since we're moving the center, adjust by height/2
        center.y += CGRectGetHeight([attrs frame]) / 2;
    }

    [attrs setCenter:center];
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
