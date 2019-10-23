
//
//  MMShelfLayoutObject.h
//  PageCollectionView
//
//  Created by Adam Wulf on 10/15/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMShelfLayoutObject <NSObject>

-(CGSize)idealSize;
-(CGFloat)rotation;

@end

NS_ASSUME_NONNULL_END
