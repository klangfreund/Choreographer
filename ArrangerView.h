//
//  ArrangerView.h
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHProjectDocument.h"
#import "CHGlobals.h"
#import "AudioItem.h"
#import "Region.h"
#import "RulerView.h"

@interface MarqueeView : NSView
{
	NSUInteger	startTime;
	float		yPosition;
	NSUInteger	duration;
	float		height;
}

- (void)setStart:(NSUInteger)start yPosition:(float)y duration:(NSInteger)dur height:(float)h;
- (void)dismiss;
- (void)recalcFrame;

@end

typedef enum _ArrangerViewDragAndDropAction
{
	arrangerViewDragInvalid = -1,
	arrangerViewDragNone = 0,
	arrangerViewDragAudioFromPool,
	arrangerViewDragTrajectoryFromPool,
	arrangerViewDragAudioFromFinder
} ArrangerViewDragAndDropAction;


@interface ArrangerView : NSView
{
	CHProjectDocument *document;
	IBOutlet id playbackController;
    IBOutlet RulerView* arrangerRuler;

    NSManagedObject *projectSettings;
	
	NSManagedObjectContext *context;

	
	// Context Menus + Popup Buttons
	IBOutlet NSMenu* regionContextMenu;
	IBOutlet id trajectoryContextMenu;
	IBOutlet NSMenu* arrangerContextMenu;
	IBOutlet id nudgeAmountMenu;
	IBOutlet id yGridLinesMenu;
	IBOutlet id xGridLinesMenu;

	IBOutlet id arrangerDisplayModePopupButton;
    IBOutlet NSWindow *repeatRegionPanel;
    
    IBOutlet NSTextField *repeatRegionTextField;

	// regions
	NSMutableArray *placeholderRegions;
	NSArray *audioRegions;
    
    // markers
    //NSArray *markers;
		
	// selection
	NSMutableSet *selectedRegions;
	NSMutableSet *tempSelectedRegions;
	Region *hitAudioRegion;
	
	id regionForSelectedTrajectories;
	NSMutableSet *selectedTrajectories;

	// properties
	NSUInteger arrangerSizeX, arrangerSizeY;
	NSMutableIndexSet *arrangerTabStops;

	// mouse actions
	ArrangerEditMode arrangerEditMode;
	BOOL draggingDirtyFlag;
	float draggingParameter[4];
	NSPoint storedEventLocation;
	
	MarqueeView *marqueeView;
	
	int xGridAmount;
	NSBezierPath *yGridPath, *xGridPath;
	

	float zoomFactorX, zoomFactorY;

	ArrangerViewDragAndDropAction arrangerViewDragAndDropAction;
}

- (void)setup;
- (void)close;

// drawing
- (void)recalculateXGridPath;
- (void)recalculateYGridPath;
- (void)recalculateArrangerProperties;
- (void)recalculateArrangerSize;

// drag and drop
- (void)trajectoryDraggingUpdated:(id <NSDraggingInfo>)info;
- (void)audioDraggingUpdated:(id <NSDraggingInfo>)info;
- (BOOL)performTrajectoryDragOperation:(id <NSDraggingInfo>)info;
- (BOOL)performAudioDragOperation:(id <NSDraggingInfo>)info;

// editing
- (void)addRegionToView:(Region *)region;
- (void)removeRegionFromView:(Region *)region;
- (void)updateZIndexInModel;

- (void)removeSelectedRegions;
- (void)recursivelyDeleteRegions:(Region *)region;
- (void)removeSelectedGainBreakpoints;

// selection
- (void)addRegionToSelection:(id)aRegion;
- (void)removeRegionFromSelection:(id)aRegion;
- (void)selectAllRegions;
- (void)deselectAllRegions;
- (BOOL)selectionIsEditable;
- (NSSet *)selectedAudioRegions;

- (void)addTrajectoryToSelection:(id)aRegion;
- (void)removeTrajectoryFromSelection:(id)aRegion;
- (void)selectAllTrajectories;
- (void)deselectAllTrajectories;

- (void)synchronizeSelection;
- (void)synchronizeMarquee;

// copying regions
- (Region *)makeUniqueCopyOf:(Region *)originalRegion;
- (Region *)makeCopyOf:(Region *)originalRegion;

// key
- (void)nudge:(NSPoint)p;

// mouse
- (id)pointInRegion:(NSPoint)point;
- (int)detailsAboutPoint:(NSPoint)point inRegion:(id)region;
- (void)showSelectionRectangle:(NSEvent *)event;

// menu actions
- (IBAction)addNewTrajectory:(id)sender;
- (IBAction)removeTrajectory:(id)sender;

- (IBAction)mute:(id)sender;
- (IBAction)lock:(id)sender;

- (IBAction)bringToFront:(id)sender;
- (IBAction)sendToBack:(id)sender;

- (IBAction)alignX:(id)sender;
- (IBAction)alignY:(id)sender;

- (IBAction)group:(id)sender;
- (IBAction)ungroup:(id)sender;

- (IBAction)selectNone:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)repeat:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)trim:(id)sender;
- (IBAction)split:(id)sender;

// context menu actions
- (IBAction)contextAddNewTrajectory:(id)sender;
- (IBAction)contextRemoveTrajectory:(id)sender;

- (IBAction)contextMute:(id)sender;
- (IBAction)contextLock:(id)sender;

// markers
- (void)recallMarker:(NSNumber *)time;

// notifications
- (void)setZoom:(NSNotification *)notification;
- (void)update:(NSNotification *)notification;
- (void)undoNotification:(NSNotification *)notification;

@end