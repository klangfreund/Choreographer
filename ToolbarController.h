//
//  ToolbarController.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ToolbarController : NSObject <NSToolbarDelegate>
{
	NSMutableDictionary *toolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems

	IBOutlet NSWindow *window;
	
	IBOutlet NSView *counterView; //the counter view (ends up in an NSToolbarItem)
	IBOutlet NSView *loopCounterView; //the loop counter view (ends up in an NSToolbarItem)
	IBOutlet NSView *transportView; //the transport view (ends up in an NSToolbarItem)
	IBOutlet NSView *loopModeView; //the transport view (ends up in an NSToolbarItem)
	IBOutlet NSView *masterVolumeSlider;
	
	IBOutlet NSButton *splitButton;
	IBOutlet NSButton *trimButton;
}

@end