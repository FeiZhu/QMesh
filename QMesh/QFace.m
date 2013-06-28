//
//  QFace.m
//  QMesh
//
//  Created by piggy on 13-6-13.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QFace.h"
#import "QVec3d.h"
#import "QVertex.h"

@interface QFace()
{
    NSMutableArray *vertices;
}
@end

@implementation QFace

@synthesize hasFaceNormal = _hasFaceNormal;
@synthesize faceNormal = _faceNormal;

- (NSUInteger)getNumVertices
{
    return [vertices count];
}

- (QVertex*)getVertexAtIndex:(NSUInteger)index
{
    return vertices[index];
}

- (id)init
{
    if(self = [super init])
    {
        vertices = [[NSMutableArray alloc] init];
        self.faceNormal = [[QVec3d alloc] init];
        self.hasFaceNormal = NO;
    }
    return self;
}

- (id)initFromVertices:(QVertex *)vertex, ...
{
    if(self = [super init])
    {
        vertices = [[NSMutableArray alloc] init];
        va_list argList;
        va_start(argList, vertex);
        while (YES)
        {
            QVertex *argVertex = va_arg(argList, QVertex*);
            if(argVertex)
                break;
            [vertices addObject:argVertex];
        }
        va_end(argList);
        self.hasFaceNormal = NO;
        self.faceNormal = [[QVec3d alloc] init];
    }
    return self;
}

- (void)addVertex:(QVertex *)vertex
{
    [vertices addObject:vertex];
}

@end
