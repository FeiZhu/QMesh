//
//  QMeshRender.h
//  QMesh
//
//  Created by piggy on 13-6-20.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QMesh;

@interface QMeshRender : NSObject

- (id)initWithMesh:(QMesh*)mesh;
- (void)render;
- (void)renderVertices;
- (void)renderEdges;
- (void)renderFacesAndEdges;
- (void)renderNormalsWithLength:(double)normalLength;//render normal vector, for debug purpose

- (void)enableTextures;
- (void)disableTextures;
- (void)flatShading;
- (void)smoothShading;
@end
