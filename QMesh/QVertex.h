//
//  QVertex.h
//  QMesh
//
//  Created by piggy on 13-6-13.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QVertex : NSObject

@property (assign, nonatomic) NSUInteger positionIndex;
@property (assign, nonatomic) NSUInteger normalIndex;
@property (assign, nonatomic) NSUInteger textureIndex;
@property (assign, nonatomic) BOOL hasNormal;
@property (assign, nonatomic) BOOL hasTexture;

- (id)initWithPositionIndex:(NSUInteger)positionIndex;
- (id)initWithPositionIndex:(NSUInteger)positionIndex AndTextureIndex:(NSUInteger)textureIndex;
- (id)initWithPositionIndex:(NSUInteger)positionIndex TextureIndex:(NSUInteger)textureIndex AndNormalIndex:(NSUInteger)normalIndex;

@end
