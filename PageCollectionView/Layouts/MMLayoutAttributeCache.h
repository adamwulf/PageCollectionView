//
//  MMLayoutAttributeCache.h
//  PageCollectionView
//
//  Created by Adam Wulf on 1/21/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface MMLayoutAttributeCache : NSObject

+ (instancetype)cacheWithAttributes:(UICollectionViewLayoutAttributes *)attributes;

@property(nonatomic, assign) CGRect frame;
@property(nonatomic, strong, readonly) NSArray<UICollectionViewLayoutAttributes *> *allItems;
@property(nonatomic, strong, readonly) NSArray<UICollectionViewLayoutAttributes *> *visibleItems;
@property(nonatomic, strong, readonly) NSArray<UICollectionViewLayoutAttributes *> *hiddenItems;

- (void)appendLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes;

@end

NS_ASSUME_NONNULL_END
