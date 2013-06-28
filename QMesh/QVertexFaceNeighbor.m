//
//  QVertexFaceNeighbor.m
//  QMesh
//
//  Created by piggy on 13-6-25.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QVertexFaceNeighbor.h"

@implementation QVertexFaceNeighbor

@synthesize groupIndex = _groupIndex;
@synthesize faceIndex = _faceIndex;
@synthesize faceVertexIndex = _faceVertexIndex;
@synthesize averaged = _averaged;

- (id)initWithGroupIndex:(NSUInteger)groupIndex FaceIndex:(NSUInteger)faceIndex FaceVertexIndex:(NSUInteger)faceVertexIndex Averaged:(BOOL)averaged
{
    if(self = [super init])
    {
        self.groupIndex = groupIndex;
        self.faceIndex = faceIndex;
        self.faceVertexIndex = faceVertexIndex;
        self.averaged = averaged;
    }
    return self;
}

@end
