//
//  QObjMeshLoader.m
//  QMesh
//
//  Created by piggy on 13-6-4.
//  Copyright (c) 2013年 piggy. All rights reserved.
//

#import "QObjMeshLoader.h"
#import "QMesh.h"
#import "QDDFileReader.h"
#import "QVec3d.h"
#import "QGroup.h"
#import "QMaterial.h"
#import "QVertex.h"
#import "QFace.h"

@interface QObjMeshLoader()

- (NSString*)convertWhitespaceToSingleBlanksInString:(NSString*)string;
- (BOOL)parseMaterialsOfMesh:(QMesh*)mesh InMaterialFile:(NSString*)materialFilename;
@end

@implementation QObjMeshLoader

- (BOOL) loadMesh: (QMesh **)mesh fromFile: (NSString *)fileName
{
    //NSLog(@"ObjMeshLoader %@",fileName);
    QMesh *curMesh = [[QMesh alloc] init];
    QDDFileReader *reader = [[QDDFileReader alloc] initWithFilePath:fileName];
    if(!reader)
    {
        //NSLog(@"Error: cannot open .obj file");
        return NO;
    }
    
    NSString *line;
    NSUInteger lineNum = 0;
    NSUInteger numGroupFaces = 0;
    NSUInteger groupCloneIndex = 0;
    NSUInteger numFaces = 0;
    NSUInteger currentGroup = 0;
    NSUInteger ignoreCounter = 0;
    NSUInteger currentMaterialIndex = 0;
    NSString *groupSourceName;
       
    QVec3d *defaultKa = [[QVec3d alloc] initWithOneEntry:0.2];
    QVec3d *defaultKd = [[QVec3d alloc] initWithOneEntry:0.6];
    QVec3d *defaultKs = [[QVec3d alloc] initWithOneEntry:0.0];
    QMaterial *defaultMaterial = [[QMaterial alloc] initWithName:@"default" Ka:defaultKa Kd:defaultKd Ks:defaultKs Shininess:65 textureFilename:nil];
    [curMesh addMaterial:defaultMaterial];
    
    while((line = [reader readLine]))
    {
        ++lineNum;
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        line = [self convertWhitespaceToSingleBlanksInString:line];
        NSUInteger stringLength = strlen([line UTF8String]);
        char lineCString[stringLength+1];
        strcpy(lineCString,[line UTF8String]);
        char command = lineCString[0];
        if([[line substringToIndex:1] isEqualToString:@"#"] || [[line substringToIndex:1] isEqualToString:@"\0"])
        {
            //ignore comment lines and empty lines
        }
        else if([[line substringToIndex:2] isEqualToString:@"v "])//vertex
        {
            double x,y,z;
            if(sscanf(lineCString, "v %lf %lf %lf\n",&x,&y,&z) < 3)
            {
                //NSLog(@"Error: invalid vertex %d",lineNum);
                return NO;
            }
            QVec3d *pos = [[QVec3d alloc] initWithX:x Y:y Z:z];
            [curMesh addVertexPosition:pos];
        }
        else if([[line substringToIndex:3] isEqualToString:@"vn "])//normal
        {
            double x,y,z;
            if(sscanf(lineCString, "vn %lf %lf %lf\n",&x,&y,&z) < 3)
            {
                //NSLog(@"Error: invalid normal %d",lineNum);
                return NO;
            }
            QVec3d *normal = [[QVec3d alloc] initWithX:x Y:y Z:z];
            [curMesh addVertexNormal:normal];
        }
        else if([[line substringToIndex:3] isEqualToString:@"vt "])//texture
        {
            double x,y;
            if(sscanf(lineCString, "vt %lf %lf\n",&x,&y) < 2)
            {
                //NSLog(@"Error: invalid texture coordinate %d",lineNum);
                return NO;
            }
            QVec3d *textureCoordinate = [[QVec3d alloc] initWithX:x Y:y Z:0];
            [curMesh addTextureCoordinate:textureCoordinate];
        }
        else if([[line substringToIndex:2] isEqualToString:@"g "])//group
        {
            NSString *name = [line substringFromIndex:2];
            BOOL groupFound = NO;
            NSUInteger counter = 0;
            NSUInteger numExistGroup = [curMesh getNumGroups];
            for(int i=0; i<numExistGroup; ++i)
            {
                QGroup *group = [curMesh getGroupAtIndex:i];
                if([group.name isEqualToString:name])
                {
                    currentGroup = counter;
                    groupFound = YES;
                    break;
                }
                ++counter;
            }
            if(!groupFound)
            {
                QGroup *newGroup = [[QGroup alloc] initWithName:name AndMaterialIndex:currentMaterialIndex];
                [curMesh addGroup:newGroup];
                currentGroup = [curMesh getNumGroups] - 1;
                numGroupFaces = 0;
                groupCloneIndex = 0;
                groupSourceName = name;
            }
        }
        else if([[line substringToIndex:2] isEqualToString:@"f "] || [[line substringToIndex:3] isEqualToString:@"fo "])
        {
            char *faceLine = &lineCString[2];
            if([[line substringToIndex:2] isEqualToString:@"fo"])
                faceLine = &lineCString[3];
            if([curMesh getNumGroups] == 0)
            {
                QGroup *defaultGroup = [[QGroup alloc] initWithName:@"default"];
                [curMesh addGroup:defaultGroup];
                currentGroup = 0;
            }
            
            QFace *face = [[QFace alloc] init];
            
            // the faceLine string now looks like the following:
            //   vertex1 vertex2 ... vertexn
            // where vertexi is v/t/n, v//n, v/t, or v
            char *curPos = faceLine;
            while(*curPos != '\0')
            {
                //seek for next whitespace or eof
                char *tokenEnd = curPos;
                while((*tokenEnd != ' ') && (*tokenEnd != '\0'))
                    ++tokenEnd;
                
                BOOL whiteSpace = NO;
                if(*tokenEnd == ' ')
                {
                    *tokenEnd = '\0';
                    whiteSpace = YES;
                }
                
                NSUInteger pos;
                NSUInteger nor;
                NSUInteger tex;
                BOOL hasNormal;
                BOOL hasTexture;
                
                //now, parse curPos
                if(strstr(curPos, "//") != NULL)
                {
                    // v//n
                    if(sscanf(curPos, "%u//%u",&pos,&nor) < 2)
                    {
                        //NSLog(@"Error: invalid face %d",lineNum);
                        return NO;
                    }
                    hasTexture = NO;
                    tex = 0;
                    hasNormal = YES;
                }
                else
                {
                    if(sscanf(curPos, "%u/%u/%u",&pos,&tex,&nor) != 3)
                    {
                        if(strstr(curPos, "/") != NULL)
                        {
                            // v/t
                            if(sscanf(curPos, "%u/%u",&pos,&tex) == 2)
                            {
                                hasTexture = YES;
                                hasNormal = NO;
                                nor = 0;
                            }
                            else
                            {
                                //NSLog(@"Error: invalid face %d",lineNum);
                                return NO;
                            }
                        }
                        else
                        {
                            // v
                            if(sscanf(curPos, "%u", &pos) == 1)
                            {
                                hasTexture =NO;
                                hasNormal = NO;
                                tex = 0;
                                nor = 0;
                            }
                            else
                            {
                                //NSLog(@"Error: invalid face %d",lineNum);
                                return NO;
                            }
                        }
                    }
                    else
                    {
                        // v/t/n
                        hasTexture = YES;
                        hasNormal = YES;
                    }
                }
                
                //decrease indices to make them 0-indexed
                --pos;
                if(hasTexture)
                    --tex;
                if(hasNormal)
                    --nor;
                
                QVertex *vertex;
                if(hasTexture && hasNormal)
                    vertex = [[QVertex alloc] initWithPositionIndex:pos TextureIndex:tex AndNormalIndex:nor];
                else if(hasTexture)
                    vertex = [[QVertex alloc] initWithPositionIndex:pos AndTextureIndex:tex];
                else
                    vertex = [[QVertex alloc] initWithPositionIndex:pos];
                [face addVertex:vertex];
                
                if(whiteSpace)
                {
                    *tokenEnd = ' ';
                    curPos = tokenEnd + 1;
                }
                else
                    curPos = tokenEnd;
            }
    
            ++numFaces;
            [[curMesh getGroupAtIndex:currentGroup] addFace:face];
            ++numGroupFaces;
        }
        else if([[line substringToIndex:6] isEqualToString:@"usemtl"])
        {
            //switch to a new material
            if(numGroupFaces > 0)
            {
                //usemtl without a "g" statement; must create a new group
                //first, create unique name
                NSString *newName = [[NSString alloc] initWithFormat:@"%s.%d",[groupSourceName UTF8String],groupCloneIndex];
                QGroup *newGroup = [[QGroup alloc] initWithName:newName AndMaterialIndex:currentMaterialIndex];
                [curMesh addGroup:newGroup];
                currentGroup = [curMesh getNumGroups] - 1;
                numGroupFaces = 0;
                ++groupCloneIndex;
            }
            
            BOOL materialFound = NO;
            NSUInteger counter = 0;
            char *materialName = &lineCString[7];
            NSUInteger numExistMaterial = [curMesh getNumMaterials];
            for(int i=0; i<numExistMaterial; ++i)
            {
                if([[curMesh getMaterialAtIndex:i].name isEqualToString:[NSString stringWithUTF8String:materialName]])
                {
                    currentMaterialIndex = counter;
                    //update current group
                    if([curMesh getNumGroups] == 0)
                    {
                        [curMesh addGroup:[[QGroup alloc] initWithName:@"default"]];
                        currentGroup = 0;
                    }
                    [curMesh getGroupAtIndex:currentGroup].materialIndex = currentMaterialIndex;
                    materialFound = YES;
                    break;
                }
                ++counter;
            }
            if(materialFound == NO)
            {
                //NSLog(@"Error: material %s does not exist",materialName);
                return NO;
            }
        }
        else if([[line substringToIndex:6] isEqualToString:@"mtllib"])
        {
            //parsematerials
            char *materialName = &lineCString[7];
            NSString *filePath = [fileName stringByDeletingLastPathComponent];
            NSString *materialFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithUTF8String:materialName]];
            if([self parseMaterialsOfMesh:curMesh InMaterialFile:materialFilePath] == NO)
            {
                //NSLog(@"Error: loading material failed");
                return NO;
            }
        }
        else if([[line substringToIndex:2] isEqualToString:@"s "])
        {
            //ignore 's'
            if(ignoreCounter < 5)
            {
                //NSLog(@"Warning: ignoring '%c' line",command);
                ++ignoreCounter;
            }
            if(ignoreCounter == 5)
            {
                //NSLog(@"Warning: suppressing further output of ignored lines");
                ++ignoreCounter;
            }
        }
        else
        {
            //invalid
            //NSLog(@"Error: invalid line in .obj file: %d",lineNum);
            return NO;
        }
    }
    *mesh = curMesh;
    return YES;
}

- (NSString*)convertWhitespaceToSingleBlanksInString:(NSString *)string
{
    const char *originalCStringConst = [string UTF8String];
    char originalCString[strlen(originalCStringConst)+1];
    strcpy(originalCString,originalCStringConst);
    char *p = originalCString;
    while(*p != 0)
    {
        //erase consecutive empty space characters, or end-of-string spaces
        while((*p == ' ') && ((*(p+1) == 0) || (*(p+1) == ' ')))
        {
            char *q = p;
            while(*q !=0)//move characters to the left, by one character
            {
                *q = *(q+1);
                ++q;
            }
        }
        ++p;
    }
    return [NSString stringWithUTF8String:originalCString];
}


- (BOOL)parseMaterialsOfMesh:(QMesh *)mesh InMaterialFile:(NSString *)materialFilename
{
    FILE *file;
    char buf[128];
    NSUInteger numMaterials;
    
    file = fopen([materialFilename UTF8String], "r");
    if(!file)
    {
        //NSLog(@"Error: cannot open material file");
        return NO;
    }
    
    QVec3d *Ka,*Kd,*Ks;
    double tempKa[3],tempKd[3],tempKs[3];
    double shininess;
    NSString *materialName = nil;
    NSString *textureFile = nil;
    QMaterial *mat = nil;
    //now, read in the data
    numMaterials = 0;
    while(fscanf(file, "%s",buf) != EOF)
    {
        switch (buf[0])
        {
            case '#':
                //comment
                //ignore the rest of line
                fgets(buf,sizeof(buf),file);
                break;
            case 'n':
                //newmtl
                if(numMaterials >= 1)//flush previous material
                {
                    Ka = [[QVec3d alloc] initWithX:tempKa[0] Y:tempKa[1] Z:tempKa[2]];
                    Kd = [[QVec3d alloc] initWithX:tempKd[0] Y:tempKd[1] Z:tempKd[2]];
                    Ks = [[QVec3d alloc] initWithX:tempKs[0] Y:tempKs[1] Z:tempKs[2]];
                    mat = [[QMaterial alloc] initWithName:materialName Ka:Ka Kd:Kd Ks:Ks Shininess:shininess textureFilename:textureFile];
                    [mesh addMaterial:mat];
                }
                //reset to default
                tempKa[0] = 0.1; tempKa[1] = 0.1; tempKa[2] = 0.1;
                tempKd[0] = 0.5; tempKd[1] = 0.5; tempKd[2] = 0.5;
                tempKs[0] = 0.0; tempKs[1] = 0.0; tempKs[2] = 0.0;
                shininess = 65;
                textureFile = nil;
                
                fgets(buf,sizeof(buf),file);
                sscanf(buf,"%s %s",buf,buf);
                ++numMaterials;
                materialName = [NSString stringWithUTF8String:buf];
                break;
            case 'N':
                if(buf[1] == 's')
                {
                    if(fscanf(file, "%lf",&shininess) < 1)
                    {
                        //NSLog(@"Warning: bad file syntax. Unable to read shininess");
                    }
                    //wavefront shininess is from [0, 1000], so scale for OpenGL
                    shininess *= 128.0 / 1000.0;
                }
                else
                    fgets(buf,sizeof(buf),file);//eat rest of line
                break;
            case 'K':
                switch (buf[1])
                {
                    case 'd':
                        if(fscanf(file, "%lf %lf %lf",&tempKd[0],&tempKd[1],&tempKd[2]) < 3)
                        {
                            //NSLog(@"Warning: bad file syntax. Unable to read Kd");
                        }
                        break;
                    case 's':
                        if(fscanf(file, "%lf %lf %lf",&tempKs[0],&tempKs[1],&tempKs[2]) < 3)
                        {
                            //NSLog(@"Warning: bad file syntax. Unable to read Ks");
                        }
                        break;
                    case 'a':
                        if(fscanf(file, "%lf %lf %lf",&tempKa[0],&tempKa[1],&tempKa[2]) < 3)
                        {
                            //NSLog(@"Warning: bad file syntax. Unable to read Ka");
                        }
                        break;
                    default:
                        //eat up rest of line
                        fgets(buf,sizeof(buf),file);
                        break;
                }
                break;
            case 'm':
                //we treat all texture maps (map_Ka, map_Kd, etc.) interchangibly
                fgets(buf,sizeof(buf),file);
                sscanf(buf, "%s %s",buf,buf);
                strcpy(buf,[[[NSString stringWithUTF8String:buf] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] UTF8String]);//trim newline and whitespace characters
                if((textureFile == nil) && (buf[0] != '\0'))
                {
                    //contain path info in the texture file name
                    NSString *filePath = [materialFilename stringByDeletingLastPathComponent];
                    textureFile = [filePath stringByAppendingPathComponent:[NSString stringWithUTF8String:buf]];
                    //NSLog(@"Noticed texture %@",textureFile);
                }
                break;
            default:
                //eat up rest of line
                fgets(buf,sizeof(buf),file);
                break;
        }
    }
    if(numMaterials >= 1)//flush last material
    {
        Ka = [[QVec3d alloc] initWithX:tempKa[0] Y:tempKa[1] Z:tempKa[2]];
        Kd = [[QVec3d alloc] initWithX:tempKd[0] Y:tempKd[1] Z:tempKd[2]];
        Ks = [[QVec3d alloc] initWithX:tempKs[0] Y:tempKs[1] Z:tempKs[2]];
        mat = [[QMaterial alloc] initWithName:materialName Ka:Ka Kd:Kd Ks:Ks Shininess:shininess textureFilename:textureFile];
        [mesh addMaterial:mat];
    }
    fclose(file);
    return YES;
}

@end
