//
//  QVec3d.h
//  QMesh
//
//  Created by piggy on 13-6-13.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QVec3d : NSObject

@property (assign, nonatomic) double x;
@property (assign, nonatomic) double y;
@property (assign, nonatomic) double z;

- (id)initWithX:(double)x Y:(double)y Z:(double)z;
- (id)initWithOneEntry:(double)entry;
- (id)initWithVector:(QVec3d*)vector;
- (BOOL)isEqualToVector:(QVec3d*)vector;
- (void)setVector:(QVec3d*)vector;
- (void)normalize;
- (double)norm;
- (double)len2;
@end
