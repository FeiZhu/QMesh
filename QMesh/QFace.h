//
//  QFace.h
//  QMesh
//
//  Created by piggy on 13-6-13.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QVec3d;
@class QVertex;

@interface QFace : NSObject

@property (assign, nonatomic) BOOL hasFaceNormal;
@property (strong, nonatomic) QVec3d *faceNormal;

- (NSUInteger)getNumVertices;
- (QVertex*)getVertexAtIndex:(NSUInteger)index;
- (id)init;
- (id)initFromVertices:(QVertex*)vertex,...;
- (void)addVertex:(QVertex*)vertex;

@end
