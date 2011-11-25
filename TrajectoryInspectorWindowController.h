//
//  TrajectoryInspectorWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.11.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TrajectoryItem.h"


@interface TrajectoryInspectorWindowController : NSWindowController
{
	TrajectoryItem *currentTrajectoryItem;
//	id breakpointTrajectoryItem;
//	id rotationTrajectoryItem;
//	id randomTrajectoryItem;

	IBOutlet NSView *breakpointInspectorView;
	IBOutlet NSView *rotationInspectorView;
	IBOutlet NSView *randomInspectorView;
}

+ (id)sharedTrajectoryInspectorWindowController;

- (void)showInspectorForTrajectoryItem:(id)item;

@end
