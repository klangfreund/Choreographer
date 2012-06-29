//
//  TableEditorWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 25.10.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditorWindowController.h"


@interface TableEditorWindowController : EditorWindowController
{
	IBOutlet NSTableView	*tableEditorView;

    EditorDisplayMode displayMode;
}


+ (id)sharedTableEditorWindowController;

- (void)refreshView;

// menu actions
- (IBAction)addBreakpoint:(id)sender;

// table view setting values
- (void)breakpointTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row;
- (void)rotationTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row;
- (void)randomTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row;

@end
