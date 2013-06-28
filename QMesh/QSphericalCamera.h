//
//  QSphericalCamera.h
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QVec3d;

@interface QSphericalCamera : NSObject

- (id)initWithCameraRadius:(double)cameraRadius Longitude:(double)cameraLongitude Lattitude:(double)cameraLattitude FocusPositon:(QVec3d*)cameraFocusPosition;
- (void)moveRightByAngle:(double)angle;
- (void)moveUpByAngle:(double)angle;
- (void)zoomInByDistance:(double)distance;//negative distance means zoom out
- (void)moveInByDistance:(double)distance;
- (void)moveFocusRightByDistance:(double)distance;
- (void)moveFocusUpByDistance:(double)distance;
- (void)look;
- (void)reset;
- (double)getCameraRadius;
- (double)getDefaultCameraRadius;
- (QVec3d*)getCameraPosition;
@end
