//
//  LPPhotoRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "LPAddToAlbumRoute.h"
#import "Base64.h"
#import "AddPhotoToAlbum.h"
#import "MobileCoreServices/UTCoreTypes.h"

@implementation LPAddToAlbumRoute

@synthesize library;

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

// Decode the base64 encoded data
- (NSData*) decodeFile:(NSMutableString*)data{
    [Base64 initialize];
    NSData * result = [Base64 decode:data];
    return result;
}


// adds the movie to the saved photos album
- (NSDictionary *) movieFunction:(NSData*)movieData {

    // get path to save movie locally to ios system
    NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString  *documentsDirectory = [paths objectAtIndex:0];
    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"filename.m4v"];
    
    // save data
    [movieData writeToFile:filePath atomically:YES];
    
    // check that the saved file is correct format (m4v)
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)){
        // move data to the album
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), filePath);
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"movie added", @"results",
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
    if(error != nil){
        NSLog(@"error with saving video");
        NSLog(@"details %@", [error description]);
    }
}

// "main" method for returning a response to calabash client
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    // Receive the photo data
    NSMutableString *encodedData = [data objectForKey:@"media"];
    NSString *type = [data objectForKey:@"type"];
    NSString *result = @"photo added";    
    NSData *binaryData = [self decodeFile:encodedData];
    
    // check if the file is a video
    if (type != nil){
        return [self movieFunction:binaryData];
    }
    // otherwise must be a photo (only two supported file types!)
    else{
        NSString *album = [data objectForKey:@"album"];

        UIImage *image = [[UIImage alloc]initWithData:binaryData];
        
        // check if decoding went as expected; if not, return error
        if(encodedData != nil && image == nil){
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    @"photo not added", @"results",
                    @"FAILURE",@"outcome",
                    @"Decode failed", @"reason",
                    @"wrong size for decode; base64 string must be divisible by 4", @"details", nil];
        }
        
        // check if query requests specific album
        if(album != nil){
            self.library = [[ALAssetsLibrary alloc] init];
            __block BOOL flag = false;
            __block NSString *errorMsg;
            // if have an image add it to that album
            if(image != nil){
                [self.library saveImage:image toAlbum:album withCompletionBlock:^(NSError *error) {
                    if (error!=nil) {
                        errorMsg = [error description];
                        flag = true;
                    }
                }];
            }
            // otherwise, just create an album
            else{
                result = @"album added";
                [library addAssetsGroupAlbumWithName:album
                                         resultBlock:^(ALAssetsGroup *group) {
                                         }
                                        failureBlock:^(NSError *error) {
                                            errorMsg = [error description];
                                            flag = true;
                                        }
                 ];
            }
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
    }
    // return success!
    return [NSDictionary dictionaryWithObjectsAndKeys:
            result, @"results",
            @"SUCCESS",@"outcome",
            nil];
}

@end
