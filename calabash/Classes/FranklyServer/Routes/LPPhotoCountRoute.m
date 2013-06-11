//
//  LPPhotoCountRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "LPPhotoCountRoute.h"

@implementation LPPhotoCountRoute

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    int count = 0;
    
    // KEXIN'S CODE HERE
    // while more photos
    count++;
    // exit
    
    NSString * countString = [NSString stringWithFormat:@"%i", count];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"photos counted", @"results",
            @"SUCCESS",@"outcome",
            countString, @"count",
            nil];
}

@end
