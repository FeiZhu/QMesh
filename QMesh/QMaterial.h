//
//  QMaterial.h
//  QMesh
//
//  Created by piggy on 13-6-14.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QVec3d;

@interface QMaterial : NSObject

@property (strong, nonatomic) QVec3d *Ka;
@property (strong, nonatomic) QVec3d *Kd;
@property (strong, nonatomic) QVec3d *Ks;
@property (assign, nonatomic) double shininess;
@property (assign, nonatomic) double alpha;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *textureFilename;
@property (assign, nonatomic) BOOL hasTextureFilename;

- (id)init;
- (id)initWithName:(NSString*)name Ka:(QVec3d*)Ka Kd:(QVec3d*)Kd Ks:(QVec3d*)Ks Shininess:(double)shininess textureFilename:(NSString*)textureFilename;

@end
