//
//  QVec3dUtility.m
//  QMesh
//
//  Created by piggy on 13-6-15.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QVec3dUtility.h"
#import "QVec3d.h"

@implementation QVec3dUtility

+ (QVec3d*)addVector:(QVec3d *)vec1 WithVector:(QVec3d *)vec2
{
    QVec3d *result = [[QVec3d alloc] initWithVector:vec1];
    result.x = result.x + vec2.x;
    result.y = result.y + vec2.y;
    result.z = result.z + vec2.z;
    return result;
}

+ (QVec3d*)subVector:(QVec3d *)vec1 WithVector:(QVec3d *)vec2
{
    QVec3d *result = [[QVec3d alloc] initWithVector:vec1];
    result.x = result.x - vec2.x;
    result.y = result.y - vec2.y;
    result.z = result.z - vec2.z;
    return result;
}

+ (QVec3d*)multVector:(QVec3d *)vec WithScalar:(double)scalar
{
    QVec3d *result =[[QVec3d alloc] initWithVector:vec];
    result.x = result.x * scalar;
    result.y = result.y * scalar;
    result.z = result.z * scalar;
    return result;
}

+ (QVec3d*)divideVector:(QVec3d *)vec WithScalar:(double)scalar
{
    QVec3d *result = [[QVec3d alloc] initWithVector:vec];
    result.x = result.x / scalar;
    result.y = result.y / scalar;
    result.z = result.z / scalar;
    return result;
}

+ (double)dotVector:(QVec3d *)vec1 WithVector:(QVec3d *)vec2
{
    double result = vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z;
    return result;
}

+ (QVec3d*)crossVector:(QVec3d *)vec1 WithVector:(QVec3d *)vec2
{
    QVec3d *result = [[QVec3d alloc] initWithOneEntry:0.0];
    result.x = vec1.y*vec2.z - vec2.y*vec1.z;
    result.y = vec1.x*vec2.z*(-1) + vec2.x*vec1.z;
    result.z = vec1.x*vec2.y - vec2.x*vec1.y;
    return result;
}

@end
