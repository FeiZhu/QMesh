//
//  QGroup.m
//  QMesh
//
//  Created by piggy on 13-6-14.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QGroup.h"
#import "QFace.h"

@interface QGroup()
{
    NSMutableArray *faces;
}
@end

@implementation QGroup
@synthesize materialIndex = _materialIndex;
@synthesize name = _name;

- (NSUInteger)getNumFaces
{
    return [faces count];
}

- (QFace*)getFaceAtIndex:(NSUInteger)index
{
    return faces[index];
}

- (id)initWithName:(NSString *)name
{
    if(self = [super init])
    {
        self.name = name;
        faces = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithName:(NSString *)name AndMaterialIndex:(NSUInteger)materialIndex
{
    if(self = [super init])
    {
        self.name = name;
        self.materialIndex = materialIndex;
        faces =[[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addFace:(QFace *)face
{
    [faces addObject:face];
}

@end
