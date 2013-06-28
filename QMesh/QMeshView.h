//
//  QMeshView.h
//  QMesh
//
//  Created by piggy on 13-6-10.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    POINTS = 0,
    WIREFRAME,
    SOLID
}MeshViewRenderMode;

typedef enum{
    FLAT = 0,
    SMOOTH
}MeshViewShadeMode;

typedef enum{
    BLACK = 0,
    BLUE,
    GRAY
}MeshViewBackgroundColor;

@class QMesh;

@interface QMeshView : UIView<UIGestureRecognizerDelegate>

@property (assign, nonatomic) MeshViewRenderMode renderMode;
@property (assign, nonatomic) MeshViewShadeMode shadeMode;
@property (assign, nonatomic) MeshViewBackgroundColor backgroundColor;
@property (assign, nonatomic) BOOL enableTexture;
@property (strong, nonatomic) QMesh *curMesh;
- (void)draw;
- (NSUInteger)numBackgroundColors;
@end
