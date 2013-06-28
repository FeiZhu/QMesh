//
//  QMeshLoader.h
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QMesh;

@interface QMeshLoader : NSObject

- (BOOL) loadMesh: (QMesh **)mesh fromFile: (NSString *)fileName;

@end
