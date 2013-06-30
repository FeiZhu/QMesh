//
//  QMeshView.m
//  QMesh
//
//  Created by piggy on 13-6-10.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "QMeshView.h"
#import "QMeshRender.h"
#import "QMesh.h"
#import "QSphericalCamera.h"
#import "QVec3d.h"

@interface QMeshView()
{
    CAEAGLLayer *eaglLayer;
    EAGLContext *context;
    GLuint viewRenderbuffer, viewFramebuffer, depthRenderbuffer;
    GLint backingWidth, backingHeight;
    //for gestures
    double lastScale,lastRotation,lastX,lastY;
}
@property (strong, nonatomic) QMeshRender *meshRender;
@property (strong, nonatomic) QSphericalCamera *camera;

- (BOOL)createFrameBuffer;
- (void)destroyFrameBuffer;
- (void)setupView;
- (void)setupLighting;
- (void)perspectiveFovY:(GLfloat)fovY aspect:(GLfloat)aspect zNear:(GLfloat)zNear zFar:(GLfloat)zFar;
- (void)addGestureRecognizers;
- (void)performTapGesture:(UITapGestureRecognizer*)recognizer;
- (void)performPinGesture:(UIPinchGestureRecognizer*)recognizer;
- (void)performPanGesture:(UIPanGestureRecognizer*)recognizer;
@end

@implementation QMeshView

@synthesize meshRender = _meshRender;
@synthesize curMesh = _curMesh;
@synthesize camera = _camera;
@synthesize renderMode = _renderMode;
@synthesize shadeMode = _shadeMode;
@synthesize backgroundColor = _backgroundColor;
@synthesize enableTexture = _enableTexture;

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [EAGLContext setCurrentContext:context];
    [self destroyFrameBuffer];
    [self createFrameBuffer];
    [self setupView];
    //redraw: important
    [self draw];
}

#pragma mark -

- (void)setCurMesh:(QMesh*)newCurMesh
{
    if(_curMesh != newCurMesh)
    {
        _curMesh = newCurMesh;
        //build normals for current mesh
        [_curMesh buildNormals];
        //update meshrender with current mesh
        self.meshRender = [[QMeshRender alloc] initWithMesh:_curMesh];
        //update camera according to current mesh
        //cameraRadius = 4*meshRadius, cameraFocusPosition = meshCentroid
        double meshRadius;
        QVec3d *meshCentroid;
        [_curMesh getMeshCentroid:&meshCentroid Radius:&meshRadius];
        self.camera = [[QSphericalCamera alloc] initWithCameraRadius:(4.0*meshRadius) Longitude:0.0 Lattitude:0.0 FocusPositon:meshCentroid];
        //update the frustum and light according to current camera
        [self setupView];
        [self setupLighting];
    }
}

- (NSUInteger)numBackgroundColors
{
    return 3;
}

#pragma mark -

- (BOOL)createFrameBuffer
{
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage: GL_RENDERBUFFER_OES fromDrawable:eaglLayer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    glGenRenderbuffersOES(1, &depthRenderbuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x",glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    return YES;
}

- (void)destroyFrameBuffer
{
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    glDeleteRenderbuffersOES(1, &depthRenderbuffer);
    depthRenderbuffer = 0;
}

- (void)setupView
{
    glViewport(0, 0, backingWidth, backingHeight);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    GLfloat zNear = 0.0f, zFar = 1.0f;
    if(self.camera)
    {
        //zNear = 0.01*cameraRadius, zFar = 100*cameraRadius
        zNear = 0.01*[self.camera getDefaultCameraRadius];
        zFar = 100.0*[self.camera getDefaultCameraRadius];
    }
    [self perspectiveFovY:45 aspect:1.0*backingWidth/backingHeight zNear:zNear zFar:zFar];
}

//set up lighting according to the position of camera
- (void)setupLighting
{
    glDisable(GL_LIGHTING);
    GLfloat lightPosition[] = {1.0,1.0,1.0,0.0};//default position
    if(self.camera)
    {
        QVec3d *cameraPosition = [self.camera getCameraPosition];
        lightPosition[0] = cameraPosition.x;
        lightPosition[1] = cameraPosition.y;
        lightPosition[2] = cameraPosition.z;
    }
    //white light
    GLfloat lightAmbient[] = {1.0,1.0,1.0,1.0};
    GLfloat lightDiffuse[] = {1.0,1.0,1.0,1.0};
    GLfloat lightSpecular[] = {1.0,1.0,1.0,1.0};
    
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse);
    glLightfv(GL_LIGHT0, GL_SPECULAR, lightSpecular);
    //light position relative to camera position: rotate around y 45 degrees, rotate around x -45 degrees
    //all counter clockwise
    //glMatrixMode(GL_MODELVIEW);
    //glPushMatrix();
    //glRotatef(45.0, 0.0, 1.0, 0.0);
    //glRotatef(-45.0, 1.0, 0.0, 0.0);
    glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
    //glPopMatrix();
    
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self addGestureRecognizers];//add the gesture recognizers
        self.curMesh = nil; //initially no mesh
        self.meshRender = nil;
        // Initialization code
        eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,nil];
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        if(!context||![EAGLContext setCurrentContext:context]||![self createFrameBuffer])
        {
            return nil;
        }
        [self setupView];
        [self setupLighting];
        //default camera
        QVec3d *focusPosition = [[QVec3d alloc] initWithOneEntry:0.0];
        self.camera = [[QSphericalCamera alloc] initWithCameraRadius:1.0 Longitude:0.0 Lattitude:0.0 FocusPositon:focusPosition];
        //default render mode, shade mode, background color and texture mode
        self.renderMode = SOLID;
        self.shadeMode = SMOOTH;
        self.backgroundColor = GRAY;
        self.enableTexture = YES;
    }
    return self;
}

- (void)draw
{
    //begin draw
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);    
    glMatrixMode(GL_MODELVIEW);
    switch (self.backgroundColor)//set background color
    {
        case BLACK:
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            break;
        case BLUE:
            glClearColor(0.24f, 0.24f, 0.48f, 1.0f);
            break;
        case GRAY:
            glClearColor(0.78f, 0.78f, 0.78f, 1.0f);
            break;
        default:
            break;
    }
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    
    //set the camera position
    [self.camera look];
    //set shading model
    if(self.shadeMode == FLAT)
        [self.meshRender flatShading];
    else
        [self.meshRender smoothShading];
    //set texture
    if(self.enableTexture)
        [self.meshRender enableTextures];
    else
        [self.meshRender disableTextures];
    //render current mesh, if any
    switch (self.renderMode)
    {
        case POINTS:
            [self.meshRender renderVertices];
            break;
        case WIREFRAME:
            [self.meshRender renderEdges];
            break;
        case SOLID:
            [self.meshRender render];
            break;
        default:
            break;
    }
    
    //finish draw
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
}

//imitate gluPerspective()
- (void)perspectiveFovY:(GLfloat)fovY aspect:(GLfloat)aspect zNear:(GLfloat)zNear zFar:(GLfloat)zFar
{
    const GLfloat pi = 3.1415926;
    //-halfWidth = left, halfWidth = right
    //-halfHeight = bottom, halfHeight = top
    GLfloat halfWidth, halfHeight;
    halfHeight = tanf((fovY/2)/180*pi)*zNear;
    halfWidth = halfHeight*aspect;
    glFrustumf(-halfWidth, halfWidth, -halfHeight, halfHeight, zNear, zFar);
}

#pragma mark - 

- (void)addGestureRecognizers
{
    //tap
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(performTapGesture:)];
    tapRecognizer.numberOfTapsRequired = 2;//detect double tap
    [self addGestureRecognizer:tapRecognizer];
    tapRecognizer.delegate = self;
    //pin
    UIPinchGestureRecognizer *pinRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(performPinGesture:)];
    [self addGestureRecognizer:pinRecognizer];
    pinRecognizer.delegate = self;
    //pan
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(performPanGesture:)];
    [self addGestureRecognizer:panRecognizer];
    panRecognizer.delegate = self;
}

- (void)performTapGesture:(UITapGestureRecognizer *)recognizer
{
    //NSLog(@"Tap");
    [self.camera reset];//double tap to reset the camera
    //[self setupLighting];//light move with camera
    //redraw
    [self draw];
}

- (void)performPinGesture:(UIPinchGestureRecognizer *)recognizer
{
    //NSLog(@"Pin");
    if([recognizer state] == UIGestureRecognizerStateBegan)
        lastScale = 1.0;
    double scale = recognizer.scale - lastScale;
    const double factor = 0.01;
    double defaultCameraRadius = [self.camera getDefaultCameraRadius];
    double currentCameraRadius = [self.camera getCameraRadius];
    double zoomDistance = currentCameraRadius>defaultCameraRadius?currentCameraRadius*scale*factor:defaultCameraRadius*scale*factor;
    [self.camera zoomInByDistance:zoomDistance];
    //[self setupLighting];
    //redraw
    [self draw];
}

- (void)performPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translatedPoint = [recognizer translationInView:self];
    if([recognizer state] == UIGestureRecognizerStateBegan)
    {
        CGPoint firstTranslation = [recognizer translationInView:self];
        lastX = firstTranslation.x;
        lastY = firstTranslation.y;
    }
    const double angle = 0.01;
    const double factor = 0.002;
    double cameraRadius = [self.camera getCameraRadius];
    double panDistanceX = translatedPoint.x - lastX;
    double panDistanceY = translatedPoint.y - lastY;
    //double aspectThreshold = 0.1;
    lastX = translatedPoint.x;
    lastY = translatedPoint.y;
    switch (recognizer.numberOfTouches)
    {
        case 1://rotate camera
            //NSLog(@"Swipe");
            [self.camera moveRightByAngle:-angle*panDistanceX];
            [self.camera moveUpByAngle:angle*panDistanceY];
            break;
        case 3://pan camera
            //NSLog(@"Pan");
            panDistanceX = panDistanceX*cameraRadius*factor;
            panDistanceY = panDistanceY*cameraRadius*factor;
            [self.camera moveFocusRightByDistance:-panDistanceX];
            [self.camera moveFocusUpByDistance:panDistanceY];
            break;
        default:
            break;
    }
    //[self setupLighting];
    //redraw
    [self draw];
}

@end
