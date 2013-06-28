//
//  QVertex.m
//  QMesh
//
//  Created by piggy on 13-6-13.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QVertex.h"

@implementation QVertex

@synthesize positionIndex = _positionIndex;
@synthesize normalIndex = _normalIndex;
@synthesize textureIndex = _textureIndex;
@synthesize hasNormal = _hasNormal;
@synthesize hasTexture = _hasTexture;

//init vertex with only its index in the position list
- (id)initWithPositionIndex:(NSUInteger)positionIndex
{
    if(self = [super init])
    {
        self.positionIndex = positionIndex;
        self.normalIndex = 0;
        self.textureIndex = 0;
        self.hasTexture = NO;
        self.hasNormal = NO;
    }
    return self;
}

//init vertex with its index in the position list and texture list
- (id)initWithPositionIndex:(NSUInteger)positionIndex AndTextureIndex:(NSUInteger)textureIndex
{
    if(self = [super init])
    {
        self.positionIndex = positionIndex;
        self.normalIndex = 0;
        self.textureIndex = textureIndex;
        self.hasNormal = NO;
        self.hasTexture = YES;
    }
    return self;
}

//init vertex with its index in the position list, texture list and normal list
- (id)initWithPositionIndex:(NSUInteger)positionIndex TextureIndex:(NSUInteger)textureIndex AndNormalIndex:(NSUInteger)normalIndex
{
    if(self = [super init])
    {
        self.positionIndex = positionIndex;
        self.normalIndex = normalIndex;
        self.textureIndex = textureIndex;
        self.hasNormal = YES;
        self.hasTexture = YES;
    }
    return self;
}

@end
