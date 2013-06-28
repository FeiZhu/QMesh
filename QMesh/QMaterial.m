//
//  QMaterial.m
//  QMesh
//
//  Created by piggy on 13-6-14.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QMaterial.h"
#import "QVec3d.h"
#import "QVec3dUtility.h"

@implementation QMaterial

@synthesize Ka = _Ka;
@synthesize Kd = _Kd;
@synthesize Ks = _Ks;
@synthesize shininess = _shininess;
@synthesize alpha = _alpha;
@synthesize name = _name;
@synthesize textureFilename = _textureFilename;
@synthesize hasTextureFilename = _hasTextureFilename;

- (id)init
{
    if(self = [super init])
    {
        self.Ka = [[QVec3d alloc] initWithOneEntry:1.0];
        self.kd = [[QVec3d alloc] initWithOneEntry:1.0];
        self.ks = [[QVec3d alloc] initWithOneEntry:1.0];
        self.shininess = 0.0;
        self.alpha = 1.0;
        self.name = @"default";
        self.textureFilename = nil;
        self.hasTextureFilename = NO;
    }
    return self;
}

- (id)initWithName:(NSString *)name Ka:(QVec3d *)Ka Kd:(QVec3d *)Kd Ks:(QVec3d *)Ks Shininess:(double)shininess textureFilename:(NSString *)textureFilename
{
    if(self = [super init])
    {
        self.Ka = Ka;
        self.Kd = Kd;
        self.Ks = Ks;
        self.shininess = shininess;
        self.alpha = 1.0;
        self.name = name;
        self.textureFilename = textureFilename;
        if(textureFilename)
            self.hasTextureFilename = YES;
        else
            self.hasTextureFilename = NO;
    }
    return self;
}

@end
