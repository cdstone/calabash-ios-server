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

NSString *errorMsg;
NSArray *result;

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
        // copy data to the album
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), filePath);
    }
    // return error - incorrect format
    else {
        [self failWithMessageFormat:@"file at path not compatible with m4v format" message:nil];
    }
}

// completion selector for saving the video to the saved photos album
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    // check for error
    if(error != nil){
        [self failWithMessageFormat:@"video not added" message:errorMsg];
    }
    else{
        result = [NSArray arrayWithObject:@"video added"];
        [self succeedWithResult:result];
        // delete the now duplicated data
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:&error];
        // log if there's an error deleting the file (at worst, there will be one extra video file)
        if(error != nil){
            NSLog(@"File deletion failed");
            NSLog(@"details: %@", [error description]);
        }
    }
}

// adds the photo to an album OR adds an album
- (void) photoFunction:(NSData*)imageData toAlbum:(NSString*)album justAlbum:(BOOL)albumBOOL {
    
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    
    // check if decoding went as expected; if not, return error
    if(image == nil && !albumBOOL){
        [self failWithMessageFormat:@"Decode failed; file type incorrect" message:nil];
    }
    else{
        // check if query requests specific album
        if(![album isEqualToString:@"default"]){
            self.library = [[ALAssetsLibrary alloc] init];
            __block NSString *errorMsg;
            // add it to the album using a background method
            void (^completionBlock)(NSError*) = ^(NSError *error){
                if (error!=nil) {
                    errorMsg = [error description];
                    [self failWithMessageFormat:@"photo not added" message:errorMsg];
                }
                if(albumBOOL){
                    result = [NSArray arrayWithObject:@"album added"];
                }
                else{
                    result = [NSArray arrayWithObject:@"photo added"];
                }
                [self succeedWithResult:result];
            };
            
            [library saveImage:image toAlbum:album withCompletionBlock:completionBlock];
            // check for error
        }
        else {
            // save to Saved Photos if no album provided
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            result = [NSArray arrayWithObject:@"photo added"];
            [self succeedWithResult:result];
        }
    }
}

// start the operation
- (void) beginOperation {
    // Receive the media data
    NSString *encodedData = [self.data objectForKey:@"media"];
    NSString *type = [self.data objectForKey:@"type"];
    NSString *album = [self.data objectForKey:@"album"];
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
        [self photoFunction:binaryData toAlbum:album justAlbum:false];
    }
    
    // otherwise, just create an album
    else{
        [self photoFunction:binaryData toAlbum:album justAlbum:true];
    }    
}

@end
