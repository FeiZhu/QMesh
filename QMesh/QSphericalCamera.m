//
//  QSphericalCamera.m
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "QSphericalCamera.h"
#import "QVec3d.h"
#import "QVec3dUtility.h"

#define S_PI  3.1415926

@interface QSphericalCamera()
{
    double defaultRadius,radius;
    double defaultPhi,phi;
    double defaultTheta,theta;
    QVec3d *defaultFocusPosition,*focusPosition;//where the camera is aiming at, in world coordinate frame
    QVec3d *up;//the up vector, in world coordinate frame
    QVec3d *cameraPosition;//position of the camera, in world coordinate
    //the camera coordinate system axes; xAxis is parallel to xz-plane, zAxis points towards focus position
    QVec3d *xAxis;
    QVec3d *yAxis;
    QVec3d *zAxis;
}
- (void)computeCameraPosition;
- (void)computeLocalCoordinateSystem;

@end

@implementation QSphericalCamera

- (id)initWithCameraRadius:(double)cameraRadius Longitude:(double)cameraLongitude Lattitude:(double)cameraLattitude FocusPositon:(QVec3d*)cameraFocusPosition
{
    if(self = [super init])
    {
        defaultRadius = cameraRadius;
        defaultPhi = cameraLongitude/360*(2*S_PI);
        defaultTheta = cameraLattitude/360*(2*S_PI);
        defaultFocusPosition = cameraFocusPosition;
        up = [[QVec3d alloc] initWithX:0 Y:1 Z:0];
        
        cameraPosition = [[QVec3d alloc] init];
        xAxis = [[QVec3d alloc] init];
        yAxis = [[QVec3d alloc] init];
        zAxis = [[QVec3d alloc] init];
        [self reset];
    }
    return self;
}

- (void)moveRightByAngle:(double)angle
{
    phi += angle;
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)moveUpByAngle:(double)angle
{
    theta += angle;
    NSLog(@"%f",theta);
    
    if (theta > 89.0 * S_PI / 180)
        theta = 89.0 * S_PI / 180;
    
    if (theta < -89.0 * S_PI / 180)
        theta = -89.0 * S_PI / 180;
     
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)zoomInByDistance:(double)distance
{
    radius -= distance;
    if(radius < 0.0)
        radius = 0.0;
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)moveInByDistance:(double)distance
{
    focusPosition.x += distance*zAxis.x;
    focusPosition.y += distance*zAxis.y;
    focusPosition.z += distance*zAxis.z;
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)moveFocusRightByDistance:(double)distance
{
    focusPosition.x += distance*xAxis.x;
    focusPosition.y += distance*xAxis.y;
    focusPosition.z += distance*xAxis.z;
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)moveFocusUpByDistance:(double)distance
{
    focusPosition.x += distance*yAxis.x;
    focusPosition.y += distance*yAxis.y;
    focusPosition.z += distance*yAxis.z;
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)look
{
    //imitate gluLookAt to set the OpenGL modelview matrix, corresponding to current camera position, focus and up vector
    GLfloat m[16];
    //make rotation matrix
    QVec3d *yVec = up;
    [yVec normalize];
    QVec3d *zVec = [QVec3dUtility subVector:cameraPosition WithVector:focusPosition];
    [zVec normalize];
    QVec3d *xVec = [QVec3dUtility crossVector:yVec WithVector:zVec];
    yVec = [QVec3dUtility crossVector:zVec WithVector:xVec];
    [xVec normalize];
    [yVec normalize];
#define M(row,col) m[col*4+row]
    M(0,0) = xVec.x;
    M(0,1) = xVec.y;
    M(0,2) = xVec.z;
    M(0,3) = 0.0;
    M(1,0) = yVec.x;
    M(1,1) = yVec.y;
    M(1,2) = yVec.z;
    M(1,3) = 0.0;
    M(2,0) = zVec.x;
    M(2,1) = zVec.y;
    M(2,2) = zVec.z;
    M(2,3) = 0.0;
    M(3,0) = 0.0;
    M(3,1) = 0.0;
    M(3,2) = 0.0;
    M(3,3) = 1.0;
#undef M
    glMultMatrixf(m);
    //translate eye to origin
    GLfloat eyex = cameraPosition.x;
    GLfloat eyey = cameraPosition.y;
    GLfloat eyez = cameraPosition.z;
    glTranslatef(-eyex, -eyey, -eyez);
}

- (void)reset
{
    radius = defaultRadius;
    phi = defaultPhi;
    theta = defaultTheta;
    focusPosition = [[QVec3d alloc] initWithVector:defaultFocusPosition];
    [self computeCameraPosition];
    [self computeLocalCoordinateSystem];
}

- (void)computeCameraPosition
{
    cameraPosition.x = focusPosition.x + radius*cos(phi)*cos(theta);
    cameraPosition.y = focusPosition.y + radius*sin(theta);
    cameraPosition.z = focusPosition.z - radius*sin(phi)*cos(theta);
}

- (void)computeLocalCoordinateSystem
{
    xAxis.x = -radius*sin(phi)*cos(theta);
    xAxis.y = 0;
    xAxis.z = -radius*cos(phi)*cos(theta);
    
    yAxis.x = -radius*cos(phi)*sin(theta);
    yAxis.y = radius*cos(theta);
    yAxis.z = radius*sin(phi)*sin(theta);
    
    zAxis.x = cameraPosition.x - focusPosition.x;
    zAxis.y = cameraPosition.y - focusPosition.y;
    zAxis.z = cameraPosition.z - focusPosition.z;
    
    [xAxis normalize];
    [yAxis normalize];
    [zAxis normalize];
}

- (double)getCameraRadius
{
    return radius;
}

- (double)getDefaultCameraRadius
{
    return defaultRadius;
}

- (QVec3d*)getCameraPosition
{
    return cameraPosition;
}

@end
