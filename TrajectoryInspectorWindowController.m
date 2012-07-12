//
//  TrajectoryInspectorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 19.11.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "TrajectoryInspectorWindowController.h"


static TrajectoryInspectorWindowController *sharedTrajectoryInspectorWindowController = nil;

@implementation TrajectoryInspectorWindowController

+(id)sharedTrajectoryInspectorWindowController
{
    if (!sharedTrajectoryInspectorWindowController)
	{
        sharedTrajectoryInspectorWindowController = [[TrajectoryInspectorWindowController alloc] init];
    }
    return sharedTrajectoryInspectorWindowController;
}

- (id)init
{
	self = [super init];
	if(self)
	{
        [NSBundle loadNibNamed:@"TrajectoryInspector" owner:self];
	}
	
	return self;
}

- (void)showInspectorModalForWindow:(NSWindow *)window trajectoryItem:(id)item
{
	[self setValue:item forKey:@"currentTrajectoryItem"];
        
    switch ([[currentTrajectoryItem valueForKey:@"trajectoryType"] intValue])
	{
		case breakpointType:
			sheet = breakpointInspectorWindow;
			break;
		case rotationAngleType:
        case rotationSpeedType:
			sheet = rotationInspectorWindow;
			break;
		case randomType:
        case circularRandomType:
			sheet = randomInspectorWindow;
			break;
	}
    
    [NSApp beginSheet:sheet
	   modalForWindow:window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (void)inspectorSheetOK
{
	[NSApp endSheet:sheet returnCode:NSOKButton];
	[sheet orderOut:nil];
}

// text field delegate method
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	[[[notification object] window] performSelectorOnMainThread:@selector(makeFirstResponder:) withObject:nil waitUntilDone:NO];

	NSWindowController *windowController = [[[[NSDocumentController sharedDocumentController] currentDocument] windowControllers] objectAtIndex:0];
	[[windowController window] makeKeyAndOrderFront:nil];
	
	[currentTrajectoryItem archiveData];
	
//	id document = [[NSDocumentController sharedDocumentController] currentDocument];
//	NSLog(@"window %@", [document window]);
//	NSLog(@"arranger view %@", [document valueForKey:@"arrangerView"]);
//	[[document window] makeFirstResponder:(NSResponder *)[document valueForKey:@"arrangerView"]];
}

@end
