//
//  QVertexFaceNeighbor.h
//  QMesh
//
//  Created by piggy on 13-6-25.
//  Copyright (c) 2013年 piggy. All rights reserved.
//
//  Stores the information about a face that is adjacent to a vertex

#import <Foundation/Foundation.h>

@interface QVertexFaceNeighbor : NSObject

@property(assign, nonatomic) NSUInteger groupIndex;
@property(assign, nonatomic) NSUInteger faceIndex;//index of the face in the group
@property(assign, nonatomic) NSUInteger faceVertexIndex;//index of the vertex in this face
@property(assign, nonatomic) BOOL averaged;

-(id)initWithGroupIndex:(NSUInteger)groupIndex FaceIndex:(NSUInteger)faceIndex FaceVertexIndex:(NSUInteger)faceVertexIndex Averaged:(BOOL)averaged;
@end
