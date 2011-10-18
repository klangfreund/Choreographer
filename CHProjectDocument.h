//
//  CHProjectDocument.h
//  Choreographer
//
//  Created by Philippe Kocher on 12.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "PoolViewController.h"

@class ArrangerView;

@interface CHProjectDocument : NSPersistentDocument
{
    NSManagedObject *projectSettings;

	IBOutlet id toolbarController;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSTreeController *treeController;
	IBOutlet ArrangerView *arrangerView;
	IBOutlet id playbackController;
	IBOutlet id bounceToDiskController;
	IBOutlet NSTextField *projectSampleRateTextField;
	
	PoolViewController *poolViewController;
	
	NSArray *draggedAudioRegions;
	NSArray *draggedTrajectories;
	
	Modifiers keyboardModifierKeys;
}

@property (assign) PoolViewController *poolViewController;
@property Modifiers keyboardModifierKeys;

- (void)setup;


// actions (menu)
- (IBAction)bounceToDisk:(id)sender;
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
- (void)setProjectSampleRate:(NSUInteger)val;

//- (NSWindowController *)windowController;

// selection management
- (void)selectionInPoolDidChange;
- (void)selectionInArrangerDidChange;
- (void)synchronizeEditors:(BOOL)flag;

// notifications
//- (void)undoNotification:(NSNotification *)notification;

@end
