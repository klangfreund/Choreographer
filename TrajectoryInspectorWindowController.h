//
//  TrajectoryInspectorWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.11.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TrajectoryItem.h"


@interface TrajectoryInspectorWindowController : NSObject  //NSWindowController
{
	TrajectoryItem *currentTrajectoryItem;
    NSWindow *sheet;
    
	IBOutlet NSWindow *breakpointInspectorWindow;
	IBOutlet NSWindow *rotationInspectorWindow;
	IBOutlet NSWindow *randomInspectorWindow;
}

+ (id)sharedTrajectoryInspectorWindowController;

- (void)showInspectorModalForWindow:(NSWindow *)window trajectoryItem:(id)item;
- (void)inspectorSheetOK;

@end
