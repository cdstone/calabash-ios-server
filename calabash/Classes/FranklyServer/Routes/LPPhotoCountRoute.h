//
//  LPPhotoCountRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "LPRoute.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LPPhotoCountRoute : NSObject<LPRoute>

@property (strong, atomic) ALAssetsLibrary* library;

@end
