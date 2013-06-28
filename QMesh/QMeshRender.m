//
//  QMeshRender.m
//  QMesh
//
//  Created by piggy on 13-6-20.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "QMeshRender.h"
#import "QMesh.h"
#import "QGroup.h"
#import "QMaterial.h"
#import "QVec3d.h"
#import "QFace.h"
#import "QVertex.h"

//flags
//geometry mode
#define MESHRENDER_TRIANGLES (1 << 0)
#define MESHRENDER_EDGES (1 << 1)
#define MESHRENDER_VERTICES (1 << 2)
//render mode
#define MESHRENDER_NONE       (0) //render with only vertices
#define MESHRENDER_FLAT        (1 << 0) //render with facet normals
#define MESHRENDER_SMOOTH      (1 << 1) //render with vertex normals
#define MESHRENDER_TEXTURE     (1 << 2) //render with texture coordinates
#define MESHRENDER_MATERIAL    (1 << 3) //render with materials
//texture mode
#define MESHRENDER_LIGHTINGMODULATIONBIT 1
#define MESHRENDER_GL_REPLACE 0
#define MESHRENDER_GL_MODULATE 1

#define MESHRENDER_MIPMAPBIT 2
#define MESHRENDER_GL_NOMIPMAP 0
#define MESHRENDER_GL_USEMIPMAP 2

@interface QMeshRender()
{
    NSMutableArray *textures;
    NSMutableArray *texturesLoad;
}
@property(strong, nonatomic) QMesh *mesh;
@property(assign, nonatomic) NSUInteger renderMode;
@property(assign, nonatomic) NSUInteger textureMode;
@property(assign, nonatomic) BOOL texturesAllLoad;
- (void)renderInGeometryMode:(NSInteger)geometryMode RenderMode:(NSInteger)renderMode;
- (void)loadTextures;
@end

@implementation QMeshRender

@synthesize mesh = _mesh;
@synthesize renderMode = _renderMode;
@synthesize textureMode = _textureMode;
@synthesize texturesAllLoad = _texturesAllLoad;

- (id)initWithMesh:(QMesh *)mesh
{
    if(self = [super init])
    {
        self.mesh = mesh;
        self.renderMode = MESHRENDER_SMOOTH | MESHRENDER_MATERIAL;//default render mode
        self.textureMode = MESHRENDER_GL_MODULATE | MESHRENDER_GL_NOMIPMAP;//default texture mode
        self.texturesAllLoad = NO;
        textures = [[NSMutableArray alloc] init];
        texturesLoad = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)render
{
    [self renderInGeometryMode:MESHRENDER_TRIANGLES RenderMode:self.renderMode];
}

- (void)renderVertices
{
    [self renderInGeometryMode:MESHRENDER_VERTICES RenderMode:self.renderMode];
}

- (void)renderEdges
{
    [self renderInGeometryMode:MESHRENDER_EDGES RenderMode:self.renderMode];
}

- (void)renderFacesAndEdges
{
    [self renderInGeometryMode:MESHRENDER_TRIANGLES | MESHRENDER_EDGES RenderMode:self.renderMode];
}

- (void)renderNormalsWithLength:(double)normalLength
{
    QVec3d *meshCenter;
    double meshRadius;
    [self.mesh getMeshCentroid:&meshCenter Radius:&meshRadius];
    NSUInteger numGroups = [self.mesh getNumGroups];
    NSMutableArray *vertexArray = [[NSMutableArray alloc] init];
    for(NSUInteger i=0; i<numGroups; ++i)
    {
        QGroup *group = [self.mesh getGroupAtIndex:i];
        NSUInteger numFaces =  [group getNumFaces];
        for(NSUInteger iFace=0; iFace<numFaces; ++iFace)
        {
            QFace *face = [group getFaceAtIndex:iFace];
            NSUInteger numVertices = [face getNumVertices];
            for(NSUInteger iVertex=0; iVertex<numVertices; ++iVertex)
            {
                QVertex *vertex = [face getVertexAtIndex:iVertex];
                QVec3d *v = [self.mesh getPositionForVertex:vertex];
                //compute end point
                QVec3d *vnormalEnd;
                QVec3d *vnormal = [self.mesh getNormalForVertex:vertex];
                if(vertex.hasNormal)
                {
                    vnormalEnd = [[QVec3d alloc] init];
                    vnormalEnd.x = v.x + normalLength*meshRadius*2*vnormal.x;
                    vnormalEnd.y = v.y + normalLength*meshRadius*2*vnormal.y;
                    vnormalEnd.z = v.z + normalLength*meshRadius*2*vnormal.z;
                }
                else
                    vnormalEnd = [[QVec3d alloc] initWithVector:v];
                [vertexArray addObject:v];
                [vertexArray addObject:vnormalEnd];
            }
        }
    }
    NSUInteger arrayCount = [vertexArray count];
    GLfloat *vertices = (GLfloat*)malloc(sizeof(GLfloat)*arrayCount*3);
    for(NSUInteger i = 0; i < arrayCount; ++i)
    {
        QVec3d *pos = vertexArray[i];
        vertices[3*i+0] = pos.x;
        vertices[3*i+1] = pos.y;
        vertices[3*i+2] = pos.z;
    }
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDrawArrays(GL_LINES, 0, arrayCount/2);
    glDisableClientState(GL_VERTEX_ARRAY);
    free(vertices);
}

- (void)enableTextures
{
    self.renderMode = self.renderMode | MESHRENDER_TEXTURE;
    if(self.texturesAllLoad == NO)
    {
        //default texture mode
        [self loadTextures];
        self.texturesAllLoad = YES;
    }
}

- (void)disableTextures
{
    self.renderMode = self.renderMode & (~MESHRENDER_TEXTURE);
}

- (void)flatShading
{
    self.renderMode = self.renderMode | MESHRENDER_FLAT;
    self.renderMode = self.renderMode & (~MESHRENDER_SMOOTH);//cannot conflict
}

- (void)smoothShading
{
    self.renderMode = self.renderMode | MESHRENDER_SMOOTH;
    self.renderMode = self.renderMode & (~MESHRENDER_FLAT);
}

- (void)renderInGeometryMode:(NSInteger)geometryMode RenderMode:(NSInteger)renderMode
{
    BOOL warnMissingNormals = NO;
    BOOL warnMissingFaceNormals = NO;
    BOOL warnMissingTextureCoordinates = NO;
    BOOL warnMissingTextures = NO;
    
    GLboolean lightingInitiallyEnabled = false;
    glGetBooleanv(GL_LIGHTING, &lightingInitiallyEnabled);
    
    //resolve conflicts in render mode setting and/or mesh data
    if((renderMode & MESHRENDER_FLAT) && (renderMode & MESHRENDER_SMOOTH))
    {
        //NSLog(@"Requested both FLAT and SMOOTH rendering; SMOOTH used");
        renderMode &= ~MESHRENDER_FLAT;
    }
    
    if(renderMode & MESHRENDER_MATERIAL)
        glDisable(GL_COLOR_MATERIAL);
    
    //render triangles
    if(geometryMode & MESHRENDER_TRIANGLES)
    {
        if(geometryMode & (MESHRENDER_EDGES | MESHRENDER_VERTICES))
        {
            glEnable(GL_POLYGON_OFFSET_FILL);
            glPolygonOffset(2.0, 2.0);
        }
        NSUInteger numGroups = [self.mesh getNumGroups];
        for(NSUInteger i = 0; i < numGroups; ++i)
        {
            QGroup *group = [self.mesh getGroupAtIndex:i];
            //set material
            QMaterial *material = [self.mesh getMaterialAtIndex:group.materialIndex];
            GLfloat shininess = material.shininess;
            GLfloat alpha = material.alpha;
            GLfloat ambient[4] = {material.Ka.x, material.Ka.y,material.Ka.z, alpha};
            GLfloat diffuse[4] = {material.Kd.x, material.Kd.y, material.Kd.z, alpha};
            GLfloat specular[4] = {material.Ks.x, material.Ks.y, material.Ks.z, alpha};
            if(renderMode & MESHRENDER_MATERIAL)
            {
                glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambient);
                glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse);
                glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular);
                glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, shininess);
            }
            if((renderMode & MESHRENDER_TEXTURE) && material.hasTextureFilename)
            {
                if(group.materialIndex >= [textures count])
                {
                    //textures are out of date
                    warnMissingTextures = YES;
                }
                else if([(NSNumber*)texturesLoad[group.materialIndex] boolValue]== NO)
                    warnMissingTextures = YES;
                else
                {
                    GLuint texture = [(NSNumber*)textures[group.materialIndex] unsignedIntegerValue];
                    glBindTexture(GL_TEXTURE_2D, texture);
                    glEnable(GL_TEXTURE_2D);
                    if((self.textureMode & MESHRENDER_LIGHTINGMODULATIONBIT) == MESHRENDER_GL_REPLACE)
                        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                    else
                        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                }
            }
            NSUInteger numFaces = [group getNumFaces];
            NSMutableArray *mutableVertexArray = [[NSMutableArray alloc] init];
            NSMutableArray *mutableNormalArray = [[NSMutableArray alloc] init];
            NSMutableArray *mutableTextureArray = [[NSMutableArray alloc] init];
            for(NSUInteger iFace = 0; iFace < numFaces; ++iFace)
            {
                QFace *face = [group getFaceAtIndex:iFace];
                NSUInteger numVertices = [face getNumVertices];
                QVertex *firstVertex = [face getVertexAtIndex:0];
                QVec3d *firstPos = [self.mesh getPositionForVertex:firstVertex];
                for(NSUInteger iVertex = 1; iVertex < numVertices-1; ++iVertex)
                {
                    QVertex *vertex = [face getVertexAtIndex:iVertex];
                    QVertex *nextVertex = [face getVertexAtIndex:iVertex+1];
                    QVec3d *pos = [self.mesh getPositionForVertex:vertex];
                    QVec3d *nextPos = [self.mesh getPositionForVertex:nextVertex];
                    [mutableVertexArray addObject:firstPos];
                    [mutableVertexArray addObject:pos];
                    [mutableVertexArray addObject:nextPos];
                    //set normal
                    if(renderMode & MESHRENDER_FLAT)
                    {
                        if(face.hasFaceNormal)
                        {
                            //set vertex normal as the face normal
                            [mutableNormalArray addObject:face.faceNormal];
                            [mutableNormalArray addObject:face.faceNormal];
                            [mutableNormalArray addObject:face.faceNormal];
                        }
                        else
                        {
                            warnMissingFaceNormals = YES;
                            QVec3d *arbitraryNormal = [[QVec3d alloc] initWithX:1.0 Y:0.0 Z:0.0];
                            [mutableNormalArray addObject:arbitraryNormal];
                            [mutableNormalArray addObject:arbitraryNormal];
                            [mutableNormalArray addObject:arbitraryNormal];
                        }
                    }
                    if(renderMode & MESHRENDER_SMOOTH)
                    {
                        QVec3d *arbitraryNormal = [[QVec3d alloc] initWithX:1.0 Y:0.0 Z:0.0];
                        if(firstVertex.hasNormal)
                        {
                            QVec3d *nor = [self.mesh getNormalForVertex:firstVertex];
                            [mutableNormalArray addObject:nor];
                        }
                        else
                        {
                            warnMissingNormals = YES;
                            [mutableNormalArray addObject:arbitraryNormal];
                        }
                        if(vertex.hasNormal)
                        {
                            QVec3d *nor = [self.mesh getNormalForVertex:vertex];
                            [mutableNormalArray addObject:nor];
                        }
                        else
                        {
                            warnMissingNormals = YES;
                            [mutableNormalArray addObject:arbitraryNormal];
                        }
                        if(nextVertex.hasNormal)
                        {
                            QVec3d *nor = [self.mesh getNormalForVertex:nextVertex];
                            [mutableNormalArray addObject:nor];
                        }
                        else
                        {
                            warnMissingNormals = YES;
                            [mutableNormalArray addObject:arbitraryNormal];
                        }
                    }
                    //set texture coordinate
                    if(renderMode & MESHRENDER_TEXTURE)
                    {
                        QVec3d *arbitraryTexture = [[QVec3d alloc] initWithOneEntry:0.0];
                        if(firstVertex.hasTexture)
                        {
                            QVec3d *tex = [self.mesh getTextureCoordinateForVertex:firstVertex];
                            [mutableTextureArray addObject:tex];
                        }
                        else
                        {
                            warnMissingTextureCoordinates = YES;
                            [mutableTextureArray addObject:arbitraryTexture];
                        }
                        if(vertex.hasTexture)
                        {
                            QVec3d *tex = [self.mesh getTextureCoordinateForVertex:vertex];
                            [mutableTextureArray addObject:tex];
                        }
                        else
                        {
                            warnMissingTextureCoordinates = YES;
                            [mutableTextureArray addObject:arbitraryTexture];
                        }
                        if(nextVertex.hasTexture)
                        {
                            QVec3d *tex = [self.mesh getTextureCoordinateForVertex:nextVertex];
                            [mutableTextureArray addObject:tex];
                        }
                        else
                        {
                            warnMissingTextureCoordinates = YES;
                            [mutableTextureArray addObject:arbitraryTexture];
                        }

                    }
                }
            }
            //now draw the face
            NSUInteger numVertices = [mutableVertexArray count];
            GLfloat *vertexArray = (GLfloat*)malloc(sizeof(GLfloat)*numVertices*3);
            GLfloat *normalArray = (GLfloat*)malloc(sizeof(GLfloat)*numVertices*3);
            GLfloat *textureArray = (GLfloat*)malloc(sizeof(GLfloat)*numVertices*2);
            for(NSUInteger idx = 0; idx < numVertices; ++idx)
            {
                QVec3d *pos = mutableVertexArray[idx];
                QVec3d *nor = mutableNormalArray[idx];
                vertexArray[3*idx+0] = pos.x;
                vertexArray[3*idx+1] = pos.y;
                vertexArray[3*idx+2] = pos.z;
                normalArray[3*idx+0] = nor.x;
                normalArray[3*idx+1] = nor.y;
                normalArray[3*idx+2] = nor.z;
                if(renderMode & MESHRENDER_TEXTURE)
                {
                    QVec3d *tex = mutableTextureArray[idx];
                    textureArray[2*idx+0] = tex.x;
                    textureArray[2*idx+1] = tex.y;
                }
            }
            glVertexPointer(3, GL_FLOAT, 0, vertexArray);
            glEnableClientState(GL_VERTEX_ARRAY);
            glNormalPointer(GL_FLOAT, 0, normalArray);
            glEnableClientState(GL_NORMAL_ARRAY);
            if(renderMode & MESHRENDER_TEXTURE)
            {
                glTexCoordPointer(2, GL_FLOAT, 0, textureArray);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            }
            glDrawArrays(GL_TRIANGLES, 0, numVertices);
            free(vertexArray);
            free(textureArray);
            free(normalArray);
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_NORMAL_ARRAY);
            if(renderMode & MESHRENDER_TEXTURE)
            {
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                glDisable(GL_TEXTURE_2D);
            }
        }
        if(geometryMode & (MESHRENDER_EDGES | MESHRENDER_VERTICES))
        {
            glDisable(GL_POLYGON_OFFSET_FILL);
        }
    }
    //render vertices
    glDisable(GL_COLOR_MATERIAL);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_LIGHTING);
    if(geometryMode & MESHRENDER_VERTICES)
    {
        glPointSize(2.0);
        NSUInteger numVertices = [self.mesh getNumVertices];
        GLfloat *vertexArray = (GLfloat*)malloc(sizeof(GLfloat) * numVertices * 3);
        for(NSUInteger vIdx = 0; vIdx < numVertices; ++vIdx)
        {
            QVec3d *pos = [self.mesh getPositionForVertexAtIndex:vIdx];
            vertexArray[3*vIdx+0] = pos.x;
            vertexArray[3*vIdx+1] = pos.y;
            vertexArray[3*vIdx+2] = pos.z;
        }
        glVertexPointer(3, GL_FLOAT, 0, vertexArray);
        glEnableClientState(GL_VERTEX_ARRAY);
        glDrawArrays(GL_POINTS, 0, numVertices);
        glDisableClientState(GL_VERTEX_ARRAY);
        free(vertexArray);
    }
    //render edges
    if(geometryMode & MESHRENDER_EDGES)
    {
        glPolygonOffset(-1.0, -1.0);
        NSUInteger numGroups = [self.mesh getNumGroups];
        NSMutableArray *mutableVertexArray = [[NSMutableArray alloc] init];
        for(NSUInteger i = 0; i< numGroups; ++i)
        {
            QGroup *group = [self.mesh getGroupAtIndex:i];
            for(NSUInteger iFace = 0; iFace < [group getNumFaces]; ++iFace)
            {
                QFace *face = [group getFaceAtIndex:iFace];
                NSUInteger numVertices = [face getNumVertices];
                for(NSUInteger iVertex = 0; iVertex < numVertices; ++iVertex)
                {
                    QVertex *vertex = [face getVertexAtIndex:iVertex];
                    QVertex *nextVertex = [face getVertexAtIndex:(iVertex+1)%numVertices];
                    QVec3d *pos = [self.mesh getPositionForVertex:vertex];
                    QVec3d *nextPos = [self.mesh getPositionForVertex:nextVertex];
                    [mutableVertexArray addObject:pos];
                    [mutableVertexArray addObject:nextPos];
                }
            }
        }
        NSUInteger numVertices = [mutableVertexArray count];
        GLfloat *vertexArray = (GLfloat*)malloc(sizeof(GLfloat)*numVertices*3);
        for(NSUInteger i=0; i<numVertices; ++i)
        {
            QVec3d *pos = mutableVertexArray[i];
            vertexArray[3*i+0] = pos.x;
            vertexArray[3*i+1] = pos.y;
            vertexArray[3*i+2] = pos.z;
        }
        glVertexPointer(3, GL_FLOAT, 0, vertexArray);
        glEnableClientState(GL_VERTEX_ARRAY);
        glDrawArrays(GL_LINES, 0, numVertices);
        glDisableClientState(GL_VERTEX_ARRAY);
        free(vertexArray);
    }
    if(lightingInitiallyEnabled)
        glEnable(GL_LIGHTING);
    
    //print warnings
    //if(warnMissingNormals)
        //NSLog(@"Warning: used SMOOTH rendering with missing vertex normal(s)");
    //if(warnMissingFaceNormals)
        //NSLog(@"Warning: used FLAT rendering with missing face normal(s)");
    //if(warnMissingTextureCoordinates)
        //NSLog(@"Warning: used TEXTURE rendering with missing texture coordinate(s)");
    //if(warnMissingTextures)
        //NSLog(@"Warning: used TEXTURE rendering with un-setup texture(s)");
}

- (void)loadTextures
{
    [textures removeAllObjects];
    [texturesLoad removeAllObjects];
    NSUInteger numMaterials = [self.mesh getNumMaterials];
    for(NSUInteger i=0; i<numMaterials; ++i)
    {
        QMaterial *material = [self.mesh getMaterialAtIndex:i];
        if(material.hasTextureFilename == NO)
        {
            [textures addObject:[NSNull null]];
            [texturesLoad addObject:[NSNumber numberWithBool:NO]];
        }
        else
        {
            CGImageRef textureImage = [[UIImage imageWithContentsOfFile:material.textureFilename] CGImage];
            if(textureImage == nil)
            {
                //NSLog(@"Warning: unable to load texture %@",material.textureFilename);
                return;
            }
            NSUInteger width = CGImageGetWidth(textureImage);
            NSUInteger height = CGImageGetHeight(textureImage);
            GLubyte *texData = (GLubyte*)malloc(width*height*4);
            CGContextRef textureContent = CGBitmapContextCreate(texData, width, height, 8, width*4, CGImageGetColorSpace(textureImage), kCGImageAlphaPremultipliedLast);
            CGContextTranslateCTM(textureContent, 0, height);
            CGContextScaleCTM(textureContent, 1.0, -1.0);//very important: reverse y axis
            CGContextDrawImage(textureContent, CGRectMake(0.0, 0.0, (float)width, (float)height), textureImage);
            CGContextRelease(textureContent);
            
            [texturesLoad addObject:[NSNumber numberWithBool:YES]];
            glEnable(GL_TEXTURE_2D);
            GLuint texture;
            glGenTextures(1, &texture);
            glBindTexture(GL_TEXTURE_2D, texture);
            [textures addObject:[NSNumber numberWithUnsignedInt:texture]];
    
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            if((self.textureMode & MESHRENDER_MIPMAPBIT) == MESHRENDER_GL_USEMIPMAP)
            {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
            }
            else
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            if((self.textureMode & MESHRENDER_LIGHTINGMODULATIONBIT) == MESHRENDER_GL_REPLACE)
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
            else
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texData);
           
            free(texData);
            glDisable(GL_TEXTURE_2D);
        }
    }
}

@end
