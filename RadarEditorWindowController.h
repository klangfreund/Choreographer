//
//  RadarEditorWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditorWindowController.h"
#import "RadarEditorView.h"

@interface RadarEditorWindowController : EditorWindowController
{
	IBOutlet RadarEditorView *radarView;

	int viewMode;
	float ratio;
	float titleToolbarHeight; // the height of the window's title and toolbar
}

+(id)sharedRadarEditorWindowController;


// actions
- (void)setViewMode:(int)value;

// accessors
- (float)titleToolbarHeight;

@end
