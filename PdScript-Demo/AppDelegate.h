//
//  AppDelegate.h
//  PdScript-Demo
//
//  Created by Chris Penny on 4/29/15.
//  Copyright (c) 2015 Intrinsic Audio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PdAudioController.h"
#import "PdDispatcher.h"
#import "PdExternals.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) PdAudioController *audioController;


@end

