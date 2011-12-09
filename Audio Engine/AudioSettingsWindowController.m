//
//  AudioSettingsWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 09.12.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "AudioSettingsWindowController.h"

@implementation AudioSettingsWindowController

- (id)init
{
	self = [self initWithWindowNibName:@"AudioSettingsWindow"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"AudioSettingsWindow"];
	}
    
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
