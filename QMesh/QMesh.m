//
//  QMesh.m
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QMesh.h"
#import "QVec3d.h"
#import "QVertex.h"
#import "QGroup.h"
#import "QMaterial.h"
#import "QFace.h"
#import "QVec3dUtility.h"
#import "QVertexFaceNeighbor.h"

@interface QMesh()
{
    NSMutableArray *materials;
    NSMutableArray *groups;
    NSMutableArray *vertexPositions;
    NSMutableArray *textureCoordinates;
    NSMutableArray *normals;
    NSMutableArray *vertexFaceNeighbors;//each element is a list of faces adjacent to the vertex
}
@property(assign, nonatomic) BOOL hasVertexFaceNeighbors;
@property(assign, nonatomic) BOOL hasFaceNormals;
- (void)buildVertexFaceNeighbors;
@end

@implementation QMesh

@synthesize hasVertexFaceNeighbors = _hasVertexFaceNeighbors;

#pragma mark -

- (void)buildVertexFaceNeighbors
{
    [vertexFaceNeighbors removeAllObjects];//remove all elements
    for(NSUInteger i=0; i<[self getNumVertices]; ++i)
    {
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        [vertexFaceNeighbors addObject:tempArray];
    }
    //go through each of the faces
    NSUInteger numGroups = [self getNumGroups];
    for(NSUInteger iGroup=0; iGroup<numGroups; ++iGroup)
    {
        NSUInteger numFaces = [groups[iGroup] getNumFaces];
        for(NSUInteger iFace=0; iFace<numFaces; ++iFace)
        {
            QFace *face = [groups[iGroup] getFaceAtIndex:iFace];
            //if([face getNumVertices]<3)
                //NSLog(@"Warning: encountered a face (group=%d,face=%d) with fewer than 3 vertices.",iGroup,iFace);
            NSUInteger numVertices = [face getNumVertices];
            for(NSUInteger iVertex=0; iVertex<numVertices; ++iVertex)
            {
                QVertex *vertex = [face getVertexAtIndex:iVertex];
                QVertexFaceNeighbor *faceNeighbor = [[QVertexFaceNeighbor alloc] initWithGroupIndex:iGroup FaceIndex:iFace FaceVertexIndex:iVertex Averaged:NO];
                [vertexFaceNeighbors[vertex.positionIndex] addObject:faceNeighbor];
            }
        }
    }
    self.hasVertexFaceNeighbors = YES;
}

#pragma mark - init method

//init, alloc and init the empty arrays
- (id)init
{
    if(self = [super init])
    {
        materials = [[NSMutableArray alloc] init];
        groups = [[NSMutableArray alloc] init];
        vertexPositions = [[NSMutableArray alloc] init];
        textureCoordinates = [[NSMutableArray alloc] init];
        normals =[[NSMutableArray alloc] init];
        vertexFaceNeighbors = [[NSMutableArray alloc] init];
        self.hasVertexFaceNeighbors = NO;
        self.hasFaceNormals = NO;
    }
    return self;
}

#pragma mark - basic mesh info

- (NSUInteger)getNumVertices
{
    return [vertexPositions count];
}

- (NSUInteger)getNumFaces
{
    NSUInteger counter =0;
    for(QGroup *group in groups)
        counter += [group getNumFaces];
    return counter;
}

- (NSUInteger)getNumNormals
{
    return [normals count];
}

- (NSUInteger)getNumTextureCoordinates
{
    return [textureCoordinates count];
}

- (NSUInteger)getNumGroups
{
    return [groups count];
}

- (NSUInteger)getNumMaterials
{
    return [materials count];
}

- (void)getMeshCentroid:(QVec3d **)centroid Radius:(double*)radius
{
    (*centroid) = [[QVec3d alloc] initWithOneEntry:0];
    for(QVec3d *p in vertexPositions)
    {
        (*centroid).x += p.x;
        (*centroid).y += p.y;
        (*centroid).z += p.z;
    }
    NSUInteger numVertices = [self getNumVertices];
    (*centroid).x /= numVertices;
    (*centroid).y /= numVertices;
    (*centroid).z /= numVertices;
    double radiusSquared = 0.0;
    for(QVec3d *p in vertexPositions)
    {
        double newSquared = [[QVec3dUtility subVector:p WithVector:(*centroid)] len2];
        if(newSquared > radiusSquared)
            radiusSquared = newSquared;
    }
    (*radius) = sqrt(radiusSquared);
}

#pragma mark - member data getters/setters

- (NSUInteger)getGlobalIndexForVertex:(NSUInteger)localVertexIndex OfFace:(NSUInteger)localFaceIndex InGroup:(NSUInteger)groupIndex
{
    return [[[groups objectAtIndex:groupIndex] getFaceAtIndex:localFaceIndex] getVertexAtIndex:localVertexIndex].positionIndex;
}

- (QVec3d*)getPositionForVertexAtIndex:(NSUInteger)index
{
    return vertexPositions[index];
}

- (QVec3d*)getPositionForVertex:(QVertex *)vertex
{
    return [vertexPositions objectAtIndex:vertex.positionIndex];
}

- (QVec3d*)getTextureCoordinateAtIndex:(NSUInteger)index
{
    return textureCoordinates[index];
}

- (QVec3d*)getTextureCoordinateForVertex:(QVertex *)vertex
{
    return [textureCoordinates objectAtIndex:vertex.textureIndex];
}

- (QVec3d*)getNormalAtIndex:(NSUInteger)index
{
    return normals[index];
}

- (QVec3d*)getNormalForVertex:(QVertex *)vertex
{
    return [normals objectAtIndex:vertex.normalIndex];
}

- (void)setPosition:(QVec3d *)position ForVertexAtIndex:(NSUInteger)index
{
    vertexPositions[index] = position;
}

- (void)setPosition:(QVec3d *)position ForVertex:(QVertex *)vertex
{
    vertexPositions[vertex.positionIndex] = position;
}

- (void)setTextureCoordinate:(QVec3d *)textureCoordinate AtIndex:(NSUInteger)index
{
    textureCoordinates[index] = textureCoordinate;
}

- (void)setTextureCoordinate:(QVec3d *)textureCoordinate ForVertex:(QVertex *)vertex
{
    textureCoordinates[vertex.textureIndex] = textureCoordinate;
}

- (void)setNormal:(QVec3d *)normal AtIndex:(NSUInteger)index
{
    normals[index] = normal;
}

- (void)setNormal:(QVec3d *)normal ForVertex:(QVertex *)vertex
{
    normals[vertex.normalIndex] = normal;
}

- (QGroup*)getGroupByName:(NSString *)name
{
    for(QGroup* group in groups)
    {
        if([group.name isEqualToString:name])
            return group;
    }
    return nil;
}

- (QGroup*)getGroupAtIndex:(NSUInteger)index
{
    return groups[index];
}

- (QMaterial*)getMaterialAtIndex:(NSUInteger)index
{
    return materials[index];
}

- (void)setMaterialAlpha:(double)alpha
{
    for(QMaterial *material in materials)
        material.alpha = alpha;
}

- (void)setSingleMaterial:(QMaterial *)material
{
    materials = [NSMutableArray arrayWithObject:material];
    for(QGroup *group in groups)
        group.materialIndex = 0;
}

#pragma mark - member data adders

- (void)addMaterial:(QMaterial *)material
{
    [materials addObject:material];
}

- (void)addGroup:(QGroup *)group
{
    [groups addObject:group];
}

- (void)addVertexPosition:(QVec3d *)position
{
    [vertexPositions addObject:position];
}

- (void)addVertexNormal:(QVec3d *)normal
{
    [normals addObject:normal];
}

- (void)addTextureCoordinate:(QVec3d *)textureCoordinate
{
    [textureCoordinates addObject:textureCoordinate];
}

- (void)addFace:(QFace *)face ToGroup:(NSUInteger)groupIndex
{
    [groups[groupIndex] addFace:face];
}

#pragma mark - optional member data setters

- (void)buildVertexNormals
{
    if(self.hasVertexFaceNeighbors == NO)
        [self buildVertexFaceNeighbors];
    if(self.hasFaceNormals == NO)
        [self buildFaceNormals];
    const double thresholdAngle = 85.0;
    const double pi = 3.1415926;
    double cosAng = cos(thresholdAngle*pi/180.0);
    [normals removeAllObjects];
    NSInteger averageIndex = 0;
    NSUInteger numVertices = [self getNumVertices];
    for(NSUInteger i=0; i<numVertices; ++i)
    {
        if([vertexFaceNeighbors[i] count] == 0)
        {
            continue;//lonely vertex
        }
        QVertexFaceNeighbor *firstNeighbor = vertexFaceNeighbors[i][0];
        QFace *firstFace = [[self getGroupAtIndex:firstNeighbor.groupIndex] getFaceAtIndex:firstNeighbor.faceIndex];
        QVec3d *firstNormal = firstFace.faceNormal;
        QVec3d *average = [[QVec3d alloc] initWithOneEntry:0.0];
        BOOL averageAnything = NO;
        //find which face contribute
        for(QVertexFaceNeighbor *vertexFaceNeighbor in vertexFaceNeighbors[i])
        {
            //get angle
            QFace *currentFace = [[self getGroupAtIndex:vertexFaceNeighbor.groupIndex] getFaceAtIndex:vertexFaceNeighbor.faceIndex];
            //dot product
            if([QVec3dUtility dotVector:firstNormal WithVector:currentFace.faceNormal]>cosAng)
            {
                //is good, so contribute to average
                average.x += currentFace.faceNormal.x;
                average.y += currentFace.faceNormal.y;
                average.z += currentFace.faceNormal.z;
                vertexFaceNeighbor.averaged = YES;
                averageAnything = YES;
            }
            else
                vertexFaceNeighbor.averaged = NO;
        }
        if(averageAnything)
        {
            double norm = [average norm];
            [normals addObject:[[QVec3d alloc] initWithX:average.x/norm Y:average.y/norm Z:average.z/norm]];
            averageIndex = [normals count] - 1;
        }
        //determine consequences for associated vertices in each face
        for(QVertexFaceNeighbor *vertexFaceNeighbor in vertexFaceNeighbors[i])
        {
            QFace *currentFace = [[self getGroupAtIndex:vertexFaceNeighbor.groupIndex] getFaceAtIndex:vertexFaceNeighbor.faceIndex];
            if(vertexFaceNeighbor.averaged)
            {
                //use average for normal
                QVertex *vertex = [currentFace getVertexAtIndex:vertexFaceNeighbor.faceVertexIndex];
                vertex.normalIndex = averageIndex;
                vertex.hasNormal = YES;
            }
            else
            {
                //use face normal for normal
                [normals addObject:currentFace.faceNormal];
                QVertex *vertex = [currentFace getVertexAtIndex:vertexFaceNeighbor.faceVertexIndex];
                vertex.normalIndex = [normals count] - 1;
                vertex.hasNormal = YES;
            }
        }
    }
}

- (void)buildFaceNormals
{
    for(QGroup *group in groups)
    {
        NSUInteger numFaces = [group getNumFaces];
        for(NSUInteger iFace=0; iFace<numFaces; ++iFace)
        {
            QFace *face = [group getFaceAtIndex:iFace];
            //if([face getNumVertices]<3)
                //NSLog(@"Warning: encountered a face with fewer than 3 vertices.");
            //the three vertices
            QVec3d *pos0 = [self getPositionForVertex:[face getVertexAtIndex:0]];
            QVec3d *pos1 = [self getPositionForVertex:[face getVertexAtIndex:1]];
            QVec3d *pos2 = [self getPositionForVertex:[face getVertexAtIndex:2]];
            QVec3d *vec1 = [QVec3dUtility subVector:pos1 WithVector:pos0];
            QVec3d *vec2 = [QVec3dUtility subVector:pos2 WithVector:pos0];
            QVec3d *normal = [QVec3dUtility crossVector:vec1 WithVector:vec2];
            [normal normalize];
            if(isnan(normal.x)||isnan(normal.y)||isnan(normal.z))
            {
                //degenerate geometry; return arbitrary normal
                normal.x = 1.0;
                normal.y = 0.0;
                normal.z = 0.0;
            }
            face.faceNormal = normal;
            face.hasFaceNormal = YES;
        }
    }
    self.hasFaceNormals = YES;
}

- (void)buildNormals
{
    [self buildFaceNormals];
    [self buildVertexNormals];
}

#pragma mark -

- (BOOL)isTriangularMesh
{
    for(QGroup *group in groups)
    {
        for(NSUInteger iFace = 0; iFace < [group getNumFaces]; ++iFace)
        {
            if([[group getFaceAtIndex:iFace] getNumVertices] != 3)
                return NO;
        }
    }
    return YES;
}

@end
