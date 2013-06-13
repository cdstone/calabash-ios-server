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


-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

// Decode the base64 encoded data
- (NSData*) decodeFile:(NSString*)data{
    NSData * result = [LPResources decodeBase64WithString:data];
    return result;
}


// adds the video to the saved photos album
- (NSDictionary *) videoFunction:(NSData*)videoData {    
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
        // return
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"video added", @"results",
                @"SUCCESS",@"outcome",
                nil];
    }
    // return error - incorrect format
    else {
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"failed to write to album", @"results",
                @"FAILURE",@"outcome",
                @"file at path not compatible with m4v format", @"reason",
                nil];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    complete = true;
    if(error != nil){
        NSLog(@"error with saving video");
        NSLog(@"details: %@", [error description]);
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
- (NSDictionary *) photoFunction:(NSData*)imageData toAlbum:(NSString*)album {
    
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    
    // check if decoding went as expected; if not, return error
    if(image == nil){
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"photo not added", @"results",
                @"FAILURE",@"outcome",
                @"Decode failed", @"reason",
                @"wrong size for decode; base64 string must be divisible by 4", @"details", nil];
    }
    
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
        
    /* BACKGROUND METHOD
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
        
        while(!complete){
            
        }
    */
        
        [library saveImage:image toAlbum:album withCompletionBlock:completionBlock];
        // check for error
        if (flag){
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    @"album not added", @"results",
                    @"FAILURE",@"outcome",
                    @"Album addition failed", @"reason",
                    errorMsg, @"details", nil];
            
        }
    }
    else {
        // save to default photos if no album provided
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"photo added", @"results",
            @"SUCCESS",@"outcome",
            nil];
}


// "main" method for returning a response to calabash client
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    // Receive the media data
    NSString *encodedData = [data objectForKey:@"media"];
    NSString *type = [data objectForKey:@"type"];
    NSString *album = [data objectForKey:@"album"];
    // decode it
    NSData *binaryData = [self decodeFile:encodedData];
    
    __block NSString *errorMsg;
    __block BOOL flag = false;
    
    // check if the file is a video
    if ([type isEqualToString:@"video"]){
        // return the video operation
        return [self videoFunction:binaryData];
    }
    // check if it is a photo
    else if (encodedData != nil) {
        // return the photo operation
        return [self photoFunction:binaryData toAlbum:album];
    }
    // otherwise, just create an album
    else{
        [library addAssetsGroupAlbumWithName:album
                                 resultBlock:^(ALAssetsGroup *group) {
                                 }
                                failureBlock:^(NSError *error) {
                                    errorMsg = [error description];
                                    flag = true;
                                }
         ];
        // check for error
        if(flag){
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    @"album not added", @"results",
                    @"FAILURE",@"outcome",
                    @"Album addition failed", @"reason",
                    errorMsg, @"details", nil];
            
        }
        // return success!
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"album added", @"results",
                @"SUCCESS",@"outcome",
                nil];
        
    }
}

@end
