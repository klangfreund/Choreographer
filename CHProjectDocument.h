//
//  CHProjectDocument.h
//  Choreographer
//
//  Created by Philippe Kocher on 12.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "ProjectSettings.h"
#import "PoolViewController.h"

@class ArrangerView;

@interface CHProjectDocument : NSPersistentDocument
{
    ProjectSettings *projectSettings;

	IBOutlet NSSplitView *splitView;
	IBOutlet NSTreeController *treeController;
	IBOutlet ArrangerView *arrangerView;
	IBOutlet id playbackController;

	PoolViewController *poolViewController;
	
	NSArray *draggedAudioRegions;
	NSArray *draggedTrajectories;
	
	Modifiers keyboardModifierKeys;
}
@property Modifiers keyboardModifierKeys;

- (void)setup;


// actions (menu)
- (IBAction)xZoomIn:(id)sender;
- (IBAction)xZoomOut:(id)sender;
- (IBAction)yZoomIn:(id)sender;
- (IBAction)yZoomOut:(id)sender;
- (IBAction)importAudioFiles:(id)sender;
- (IBAction)newTrajectory:(id)sender;
- (IBAction)showPool:(id)sender;

- (void)newTrajectoryItem:(NSString *)name forRegions:(NSSet *)regions;


// IB actions

// accessors
- (float)zoomFactorX;
- (float)zoomFactorY;
- (void)setProjectSettings:(id)anything;


// selection management
- (void)selectionInPoolDidChange;
- (void)selectionInArrangerDidChange;
- (void)synchronizeEditors:(BOOL)flag;

// notifications
//- (void)undoNotification:(NSNotification *)notification;

//...
//- (void)refreshPoolViews;


@end
