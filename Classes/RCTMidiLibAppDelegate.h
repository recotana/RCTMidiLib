//
//  MidiTestForiPadAppDelegate.h
//  MidiTestForiPad
//
//  Created by recotana on 11/01/17.
//  Copyright 2011 recotana.com All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCTMidiLibViewController;

@interface RCTMidiLibAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    RCTMidiLibViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RCTMidiLibViewController *viewController;

@end

