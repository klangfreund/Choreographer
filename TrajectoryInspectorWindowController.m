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
	self = [self initWithWindowNibName:@"TrajectoryInspector"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"TrajectoryInspector"];
	}
	
	return self;
}

- (void)showInspectorForTrajectoryItem:(id)item
{
	[self showWindow:nil];
	
	currentTrajectoryItem = item;
	
	switch ([[item valueForKey:@"trajectoryType"] intValue])
	{
		case 0:
			[self setValue:item forKey:@"breakpointTrajectoryItem"];
			[[self window] setContentView:breakpointInspectorView];
			break;
		case 1:
			[self setValue:item forKey:@"rotationTrajectoryItem"];
			[[self window] setContentView:rotationInspectorView];
			break;
		case 2:
			[self setValue:item forKey:@"randomTrajectoryItem"];
			[[self window] setContentView:randomInspectorView];
			break;
	}
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
