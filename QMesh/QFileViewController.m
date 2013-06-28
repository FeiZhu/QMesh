//
//  QFileViewController.m
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QFileViewController.h"

#import "QMeshViewController.h"
#import "QMeshLoader.h"
#import "QObjMeshLoader.h"


@interface QFileViewController () {
    NSMutableArray *meshFiles;
}
@property (strong, nonatomic) QMeshLoader *meshLoader;
@end

@implementation QFileViewController

@synthesize meshViewController;
@synthesize meshLoader;

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.meshViewController = (QMeshViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    //initialize the list of mesh files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    NSError *error = nil;
    NSArray *fileList = [[NSArray alloc] init];
    fileList = [fileManager contentsOfDirectoryAtPath:documentDir error:&error];
    meshFiles = [NSMutableArray arrayWithArray:fileList];
    //remove unsupported files
    for(NSString *file in fileList)
    {
        NSString *fileExtension = [file pathExtension];
        if([fileExtension caseInsensitiveCompare:@"obj"] != NSOrderedSame)
           [meshFiles removeObject:file];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return meshFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //ios 6+
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    //ios 5
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    NSString *curMeshFile = meshFiles[indexPath.row];
    cell.textLabel.text = [curMeshFile description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *deleteFile = meshFiles[indexPath.row];
        [meshFiles removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        //remove the selected file
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[documentPaths objectAtIndex:0] stringByAppendingPathComponent:deleteFile];
        NSError *error = nil;
        [fileManager removeItemAtPath:filePath error:&error];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //load current mesh from file
    NSString *curMeshFile = meshFiles[indexPath.row];
    NSString *fileExtension = [curMeshFile pathExtension];//get the file extension of the mesh file
    //initialize the proper mesh loader
    if ([fileExtension caseInsensitiveCompare:@"obj"] == NSOrderedSame)
        self.meshLoader = [[QObjMeshLoader alloc] init];
    //load from file
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[documentPaths objectAtIndex:0] stringByAppendingPathComponent:curMeshFile];//path to current mesh file
    QMesh *tempMesh;
    if([self.meshLoader loadMesh:&tempMesh fromFile:filePath])
        [self.meshViewController setCurMeshTo:tempMesh];
    else
    {
        //NSLog(@"Loading Error!");
    }
}

@end
