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
    CGFloat _sectionWidth;
}

@dynamic delegate;

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
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:[self section]];
        id<MMShelfLayoutObject>object = [[self datasource] collectionView:[self collectionView] layout:self objectAtIndexPath:indexPath];

        CGSize itemSize = [object idealSize];
        CGFloat rotation = [object rotation];

        CGRect bounds = CGRectMake(0, 0, itemSize.width, itemSize.height);
        CGRect rotatedBounds = CGRectApplyAffineTransform(bounds, CGAffineTransformMakeRotation(rotation));
        CGSize rotatedSize = rotatedBounds.size;

        // scale up our default item size so that it fits the screen width
        rotatedSize.height = CGRectGetWidth([[self collectionView] bounds]) / rotatedSize.width * rotatedSize.height;
        rotatedSize.width = CGRectGetWidth([[self collectionView] bounds]);

        CGRect unrotatedBounds = CGRectApplyAffineTransform(CGRectMake(0, 0, rotatedSize.width, rotatedSize.height), CGAffineTransformInvert(CGAffineTransformMakeRotation(rotation)));
        itemSize = unrotatedBounds.size;

        CGFloat scale = 1;
        
        if([[self delegate] respondsToSelector:@selector(collectionView:layout:zoomScaleForIndexPath:)]){
            scale = [[self delegate] collectionView:[self collectionView] layout:self zoomScaleForIndexPath:indexPath];
        }
        
        CGFloat diff = (maxWidth - itemSize.width) / 2.0 * scale;

        if (!CGSizeEqualToSize(itemSize, CGSizeZero)) {
            // set all the attributes
            CGFloat yDiff = (itemSize.height - rotatedSize.height) / 2.0 * scale;
            UICollectionViewLayoutAttributes *itemAttrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:[self section]]];
            CGRect frame = CGRectMake(diff, yOffset - yDiff, itemSize.width, itemSize.height);

            frame.origin.x = round(frame.origin.x);
            frame.origin.y = round(frame.origin.y);
            frame.size.width = round(frame.size.width);
            frame.size.height = round(frame.size.height);

            [itemAttrs setFrame:frame];

            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeTranslation(-itemSize.width/2, -itemSize.height/2), scale, scale), itemSize.width/2, itemSize.height/2);

            if(rotation){
                transform = CGAffineTransformRotate(transform, rotation);
            }

            [itemAttrs setAlpha:1];
            [itemAttrs setHidden:NO];
            [itemAttrs setTransform:transform];

            yOffset += rotatedSize.height * scale;


            [_cache addObject:itemAttrs];

            _sectionWidth = MAX(_sectionWidth, itemSize.width * scale);
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
