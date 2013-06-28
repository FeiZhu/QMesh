//
//  QMeshViewController.m
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QMeshViewController.h"
#import "QMeshView.h"

@interface QMeshViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation QMeshViewController

#pragma mark -      

- (IBAction)setRenderMode:(id)sender
{
    QMeshView *view = (QMeshView*)self.view;
    UISegmentedControl *segControl = (UISegmentedControl*)sender;
    NSInteger selectedSeg = segControl.selectedSegmentIndex;
    switch (selectedSeg)
    {
        case 0:
            //NSLog(@"Points");
            view.renderMode = POINTS;
            break;
        case 1:
            //NSLog(@"Wireframe");
            view.renderMode = WIREFRAME;
            break;
        case 2:
            //NSLog(@"Solid");
            view.renderMode = SOLID;
            break;
        default:
            break;
    }
    [view draw];//redraw
}

- (IBAction)setShadeMode:(id)sender {
    QMeshView *view = (QMeshView*)self.view;
    UISegmentedControl *segControl = (UISegmentedControl*)sender;
    NSInteger selectedSeg = segControl.selectedSegmentIndex;
    switch (selectedSeg)
    {
        case 0:
            //NSLog(@"Flat");
            view.shadeMode = FLAT;
            break;
        case 1:
            //NSLog(@"Smooth");
            view.shadeMode = SMOOTH;
        default:
            break;
    }
    [view draw];//redraw
}

- (IBAction)setBackground:(id)sender {
    QMeshView *view = (QMeshView*)self.view;
    view.backgroundColor = (view.backgroundColor + 1) % [view numBackgroundColors];
    //redraw
    [view draw];
}

- (IBAction)switchTexture:(id)sender {
    QMeshView *view = (QMeshView*)self.view;
    view.enableTexture = !view.enableTexture;
    //redraw
    [view draw];
}

- (void)setCurMeshTo:(QMesh *)mesh
{
    //update the view's current mesh
    QMeshView *view = (QMeshView*)self.view;
    view.curMesh = mesh;
    //redraw the view
    [view draw];

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //draw the view
    QMeshView *view = (QMeshView*)self.view;
    [view draw];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Models", @"Models");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

@end
