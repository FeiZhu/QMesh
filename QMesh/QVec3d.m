//
//  QVec3d.m
//  QMesh
//
//  Created by piggy on 13-6-13.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QVec3d.h"

@implementation QVec3d

@synthesize x = _x;
@synthesize y = _y;
@synthesize z = _z;

- (id)initWithX:(double)x Y:(double)y Z:(double)z
{
    if(self = [super init])
    {
        self.x = x;
        self.y = y;
        self.z = z;
    }
    return self;
}

- (id)initWithOneEntry:(double)entry
{
    return [self initWithX:entry Y:entry Z:entry];
}

- (id)initWithVector:(QVec3d *)vector
{
    return [self initWithX:vector.x Y:vector.y Z:vector.z];
}

- (BOOL)isEqualToVector:(QVec3d *)vector
{
    if((self.x == vector.x)&&(self.y == vector.y)&&(self.z == vector.z))
        return YES;
    else return NO;
}

- (void)setVector:(QVec3d *)vector
{
    self.x = vector.x;
    self.y = vector.y;
    self.z = vector.z;
}

- (void)normalize
{
    double invMag = 1.0 / sqrt(self.x*self.x + self.y*self.y + self.z*self.z);
    self.x = self.x * invMag;
    self.y = self.y * invMag;
    self.z = self.z * invMag;
}

- (double)norm
{
    return sqrt(self.x*self.x+self.y*self.y+self.z*self.z);
}

- (double)len2
{
    return (self.x*self.x+self.y*self.y+self.z*self.z);
}

@end
