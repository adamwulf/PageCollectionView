//
//  MMGridLayout.h
//  infinite-draw
//
//  Created by Adam Wulf on 10/6/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import "MMShelfLayout.h"

NS_ASSUME_NONNULL_BEGIN


@interface MMGridLayout : MMShelfLayout

- (instancetype)initWithSection:(NSInteger)section;

@property(nonatomic, assign, readonly) NSInteger section;
@property(nonatomic, assign) UIEdgeInsets itemSpacing;

@end

NS_ASSUME_NONNULL_END
