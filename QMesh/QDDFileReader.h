//
//  QDDFileReader.h
//  QMesh
//
//  Created by piggy on 13-6-17.
//  Copyright (c) 2013年 piggy. All rights reserved.
//
//  This class was done by Dave DeLong: http://stackoverflow.com/users/115730/dave-delong
//  It allows reading a file line by line, see the post here:
//  http://stackoverflow.com/questions/1044334/objective-c-reading-a-file-line-by-line

#import <Foundation/Foundation.h>

@interface QDDFileReader : NSObject {
    NSString * filePath;
    
    NSFileHandle * fileHandle;
    unsigned long long currentOffset;
    unsigned long long totalFileLength;
    
    NSString * lineDelimiter;
    NSUInteger chunkSize;
}

@property (nonatomic, copy) NSString * lineDelimiter;
@property (nonatomic) NSUInteger chunkSize;

- (id) initWithFilePath:(NSString *)aPath;
- (NSString *) readLine;
- (NSString *) readTrimmedLine;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL *))block;
#endif

@end
