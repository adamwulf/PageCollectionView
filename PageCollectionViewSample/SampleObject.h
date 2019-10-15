//
//  SampleObject.h
//  PageCollectionViewSample
//
//  Created by Adam Wulf on 10/15/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PageCollectionView/PageCollectionView.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleObject : NSObject<MMShelfLayoutObject>

@property(nonatomic, assign) CGSize idealSize;

@end

NS_ASSUME_NONNULL_END
