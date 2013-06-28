//
//  QVec3dUtility.h
//  QMesh
//
//  Created by piggy on 13-6-15.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QVec3d;

@interface QVec3dUtility : NSObject

+ (QVec3d*)addVector:(QVec3d*)vec1 WithVector:(QVec3d*)vec2;
+ (QVec3d*)subVector:(QVec3d*)vec1 WithVector:(QVec3d*)vec2;
+ (QVec3d*)multVector:(QVec3d*)vec WithScalar:(double)scalar;
+ (QVec3d*)divideVector:(QVec3d*)vec WithScalar:(double)scalar;
+ (double)dotVector:(QVec3d*)vec1 WithVector:(QVec3d*)vec2;
+ (QVec3d*)crossVector:(QVec3d*)vec1 WithVector:(QVec3d*)vec2;

@end
