//
//  LPPhotoRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "LPPhotoAssetsLibraryRoute.h"
#import "Base64.h"
#import "AddPhotoToAlbum.h"

@implementation LPPhotoAssetsLibraryRoute

@synthesize library;

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

- (UIImage*) decodePhoto:(NSMutableString*)data{
    if (data != nil){
    // Decode the base64 encoded data
    [Base64 initialize];
    NSData * imageData = [Base64 decode:data];
    
    // create image
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    return image;
    }
    else{
        return nil;
    }
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    // Receive the photo data
    NSMutableString *encodedData = [data objectForKey:@"phto"];
    NSString *album = [data objectForKey:@"album"];
    UIImage *image = [self decodePhoto:encodedData];
    NSString *result = @"photo added";
    
    if(encodedData != nil && image == nil){
            return [NSDictionary dictionaryWithObjectsAndKeys:
                @"photo not added", @"results",
                @"FAILURE",@"outcome",
                @"Decode failed", @"reason",
                @"wrong size for decode; base64 string must be divisible by 4", @"details", nil];
    }

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
    
    // return success!
    return [NSDictionary dictionaryWithObjectsAndKeys:
            result, @"results",
            @"SUCCESS",@"outcome",
            nil];
}

@end
