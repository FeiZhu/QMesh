//
//  Mesh.h
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QVec3d;
@class QVertex;
@class QGroup;
@class QMaterial;
@class QFace;

@interface QMesh : NSObject

//init method
- (id)init;
//basic mesh info
- (NSUInteger)getNumVertices;
- (NSUInteger)getNumFaces;
- (NSUInteger)getNumNormals;
- (NSUInteger)getNumTextureCoordinates;
- (NSUInteger)getNumGroups;
- (NSUInteger)getNumMaterials;
- (void)getMeshCentroid:(QVec3d**)centroid Radius:(double*)radius;
//member data getters/setters
- (NSUInteger)getGlobalIndexForVertex:(NSUInteger)localVertexIndex OfFace: (NSUInteger)localFaceIndex InGroup: (NSUInteger)groupIndex;
- (QVec3d*)getPositionForVertexAtIndex:(NSUInteger)index;
- (QVec3d*)getPositionForVertex:(QVertex*)vertex;
- (QVec3d*)getTextureCoordinateAtIndex:(NSUInteger)index;
- (QVec3d*)getTextureCoordinateForVertex:(QVertex*)vertex;
- (QVec3d*)getNormalAtIndex:(NSUInteger)index;
- (QVec3d*)getNormalForVertex:(QVertex*)vertex;

- (void)setPosition:(QVec3d*)position ForVertexAtIndex:(NSUInteger)index;
- (void)setPosition:(QVec3d*)position ForVertex:(QVertex*)vertex;
- (void)setTextureCoordinate:(QVec3d*)textureCoordinate AtIndex:(NSUInteger)index;
- (void)setTextureCoordinate:(QVec3d*)textureCoordinate ForVertex:(QVertex*)vertex;
- (void)setNormal:(QVec3d*)normal AtIndex:(NSUInteger)index;
- (void)setNormal:(QVec3d*)normal ForVertex:(QVertex*)vertex;
- (QGroup*)getGroupByName:(NSString*)name;
- (QGroup*)getGroupAtIndex:(NSUInteger)index;
- (QMaterial*)getMaterialAtIndex:(NSUInteger)index;
- (void)setMaterialAlpha:(double)alpha;
- (void)setSingleMaterial:(QMaterial*)material;
//member data adders
- (void)addMaterial:(QMaterial*)material;
- (void)addGroup:(QGroup*)group;
- (void)addVertexPosition:(QVec3d*)position;
- (void)addVertexNormal:(QVec3d*)normal;
- (void)addTextureCoordinate:(QVec3d*)textureCoordinate;
- (void)addFace:(QFace*)face ToGroup:(NSUInteger)groupIndex;
//optional member data setters
- (void)buildVertexNormals;
- (void)buildFaceNormals;
- (void)buildNormals;//build both vertex normals and face normals
//mesh query
- (BOOL)isTriangularMesh;
@end
