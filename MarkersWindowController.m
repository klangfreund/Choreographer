//
//  MarkersWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 20.12.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "MarkersWindowController.h"

static MarkersWindowController *sharedMarkersWindowController = nil;


@implementation MarkersWindowController

+ (id)sharedMarkersWindowController
{
    if (!sharedMarkersWindowController)
	{
        sharedMarkersWindowController = [[MarkersWindowController alloc] init];
    }
    return sharedMarkersWindowController;
}

- (id)init
{
	self = [self initWithWindowNibName:@"MarkersWindow"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"MarkersWindow"];
    }
    return self;
}

@end
