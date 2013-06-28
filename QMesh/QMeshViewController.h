//
//  QMeshViewController.h
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class QMesh;

@interface QMeshViewController : UIViewController <UISplitViewControllerDelegate>

- (IBAction)setRenderMode:(id)sender;
- (IBAction)setShadeMode:(id)sender;
- (IBAction)setBackground:(id)sender;
- (IBAction)switchTexture:(id)sender;

- (void)setCurMeshTo:(QMesh*)mesh;
@end
