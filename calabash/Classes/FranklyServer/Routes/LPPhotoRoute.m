//
//  LPPhotoRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPPhotoRoute.h"
#import "LPHTTPDataResponse.h"
#import <QuartzCore/QuartzCore.h>

@implementation LPPhotoRoute

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"GET"] || [method isEqualToString:@"POST"];
}

- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    LPHTTPDataResponse* drsp = [[LPHTTPDataResponse alloc] initWithData:[self addPhoto]];
    return [drsp autorelease];
}


-(NSData*)addPhoto
{
    NSData *imageData = [self.data objectForKey:@"phto"];
    
    NSLog(@"%@", imageData);
    
    UIImage *image = [UIImage imageWithData: imageData];
    
    // KEXIN'S CODE HERE
    
    return UIImagePNGRepresentation(image);
}

@end
