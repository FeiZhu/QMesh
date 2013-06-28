//
//  QGroup.h
//  QMesh
//
//  Created by piggy on 13-6-14.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QFace;

@interface QGroup : NSObject

@property (assign, nonatomic) NSUInteger materialIndex;
@property (strong, nonatomic) NSString *name;

- (NSUInteger)getNumFaces;
- (QFace*)getFaceAtIndex:(NSUInteger)index;
- (id)initWithName:(NSString*)name;
- (id)initWithName:(NSString*)name AndMaterialIndex: (NSUInteger)materialIndex;
- (void)addFace:(QFace*)face;

@end
