//
//  LPPhotoRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//
// handles calls to add an album, add a photo, or add a video to the ios system

#import "LPAddToAlbumRoute.h"
#import "LPResources.h"
#import "AddPhotoToAlbum.h"

@implementation LPAddToAlbumRoute

@synthesize library;

BOOL complete = false;
NSString *errorMsg;
BOOL flag = false;
NSString *result;


-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

// Decode the base64 encoded data
- (NSData*) decodeFile:(NSString*)data{
    NSData * file = [LPResources decodeBase64WithString:data];
    return file;
}


// adds the video to the saved photos album
- (void) videoFunction:(NSData*)videoData {
    // get path to save video locally to ios system
    NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString  *documentsDirectory = [paths objectAtIndex:0];
    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"filename.m4v"];
    
    // save data
    [videoData writeToFile:filePath atomically:YES];
    
    // check that the saved file is correct format (m4v)
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)){
        // move data to the album
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), filePath);
        // set return values
        result = @"video added";
    }
    // return error - incorrect format
    else {
        flag = true;
        complete = true;
        result = @"file at path not compatible with m4v format";
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    complete = true;
    if(error != nil){
        flag = true;
        errorMsg = [error description];
    }
    else{
        // delete the now duplicated data
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:&error];
        // log if there's an error deleting the file (at worst, there will be one extra video file)
        if(error != nil){
            NSLog(@"File deletion failed");
            NSLog(@"details: %@", [error description]);
        }
    }
}

// adds the photo to an album
- (void) photoFunction:(NSData*)imageData toAlbum:(NSString*)album {
    
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    
    // check if decoding went as expected; if not, return error
    if(image == nil){
        flag = true;
        result = @"Decode failed; file type incorrect";
    }
    else{
        // check if query requests specific album
        if(![album isEqualToString:@"default"]){
            self.library = [[ALAssetsLibrary alloc] init];
            __block BOOL flag = false;
            __block NSString *errorMsg;
            // add it to the album using a background method
            void (^completionBlock)(NSError*) = ^(NSError *error){
                complete = true;
                if (error!=nil) {
                    errorMsg = [error description];
                    flag = true;
                }
            };
            
        /*
        // BACKGROUND METHOD
        // NOT CURRENTLY WORKING - HANGS
        // THIS IS NEEDED ON BOTH THE PHOTO AND VIDEO FUNCTIONS FOR PROPER ERROR REPORTING
        // CURRENTLY FAILURES of saveImage:toAlbum:etc., UISaveVideoAtPathetc. WILL GO UNREPORTED
             
             NSMethodSignature *sig = [library methodSignatureForSelector:@selector(saveImage:toAlbum:withCompletionBlock:)];
             NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:sig];
             [invoke setTarget:library];
             [invoke setSelector:@selector(saveImage:toAlbum:withCompletionBlock:)];
             [invoke setArgument:&image atIndex:2];
             [invoke setArgument:&album atIndex:3];
             [invoke setArgument:&completionBlock atIndex:4];
             [invoke performSelectorInBackground:@selector(invoke) withObject:nil];
        */
            
            [library saveImage:image toAlbum:album withCompletionBlock:completionBlock];
            // check for error
        }
        else {
            // save to default photos if no album provided
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
        result = @"photo added";
    }
}

- (void) albumFunction:(NSString *)album{
    [library addAssetsGroupAlbumWithName:album
                             resultBlock:^(ALAssetsGroup *group) {
                                 result = @"Album added";
                                 complete = true;
                             }
                            failureBlock:^(NSError *error) {
                                result = @"Album not added";
                                errorMsg = [error description];
                                complete = true;
                                flag = true;
                            }
     ];
    result = @"Album added";
}


// "main" method for returning a response to calabash client
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    flag = false;
    // Receive the media data
    NSString *encodedData = [data objectForKey:@"media"];
    NSString *type = [data objectForKey:@"type"];
    NSString *album = [data objectForKey:@"album"];
    // decode it
    NSData *binaryData = [self decodeFile:encodedData];
    
    // check if the file is a video
    if ([type isEqualToString:@"video"]){
        // execute the video operation
        [self videoFunction:binaryData];
    }
    
    // check if it is a photo
    else if (encodedData != nil) {
        // execute the photo operation
        [self photoFunction:binaryData toAlbum:album];
    }
    
    // otherwise, just create an album
    else{
        [self albumFunction:album];
    }
    
    // wait for completion
    // while(!complete){
        // busily
    // }
    
    // check for error
    if(flag){
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"FAILURE",@"outcome",
                result, @"reason",
                errorMsg, @"details", nil];
        
    }
    // return success!
    else{
        return [NSDictionary dictionaryWithObjectsAndKeys:
                result, @"results",
                @"SUCCESS",@"outcome",
                nil];
    }
}

@end
