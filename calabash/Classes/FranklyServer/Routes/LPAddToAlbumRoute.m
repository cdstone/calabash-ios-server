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
    
    // check that the saved file is correct format
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)){
        // copy data to the album
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), filePath);
    }
    // return error - incorrect format
    else {
        [self failWithMessageFormat:@"file at path not compatible with movie format" message:nil];
    }
}

// completion selector for saving the video to the saved photos album
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    // check for error
    if(error != nil){
        [self failWithMessageFormat:@"video not added" message:[error description]];
    }
    else{
        [self succeedWithResult:[NSArray arrayWithObject:@"video added"]];
    }
    // delete the temporary video data
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:&error];
    // log if there's an error deleting the file (at worst, there will be one extra video file)
    if(error != nil){
        NSLog(@"File deletion failed");
        NSLog(@"details: %@", [error description]);
    }
}

// adds the photo to an album
- (void) photoFunction:(NSData*)imageData toAlbum:(NSString*)album {
    
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    
    // check if decoding went as expected; if not, return error
    if(image == nil){
        [self failWithMessageFormat:@"Decode failed; file type incorrect" message:nil];
    }
    else{
        // check if query requests specific album
        if(![album isEqualToString:@"Saved Photos"]){
            self.library = [[ALAssetsLibrary alloc] init];
            // add it to the album using a background method
            void (^completionBlock)(NSError*) = ^(NSError *error){
                if (error!=nil) {
                    [self failWithMessageFormat:@"photo not added" message:[error description]];
                }
                [self succeedWithResult:[NSArray arrayWithObject:@"photo added"]];
            };
            [library saveImage:image toAlbum:album withCompletionBlock:completionBlock];
        }
        else {
            // save to Saved Photos if no album provided
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            [self succeedWithResult:[NSArray arrayWithObject:@"photo added"]];
        }
    }
}

// adds an album to the device
- (void) albumFunction:(NSString*)album {
    void (^completionBlock)(NSError*) = ^(NSError *error){
        if (error!=nil) {
            [self failWithMessageFormat:@"photo not added" message:[error description]];
        }
        [self succeedWithResult:[NSArray arrayWithObject:@"album added"]];
    };
    [library saveImage:nil toAlbum:album withCompletionBlock:completionBlock];
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
        [self photoFunction:binaryData toAlbum:album];
    }
    
    // otherwise, just create an album
    else{
        [self albumFunction:album];
    }    
}

@end
