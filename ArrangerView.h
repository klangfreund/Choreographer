//
//  ArrangerView.h
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHProjectDocument.h"
#import "ProjectSettings.h"
#import "CHGlobals.h"
#import "AudioItem.h"
#import "Region.h"

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

@interface ArrangerView : NSView
{
	CHProjectDocument *document;
	IBOutlet id playbackController;

    ProjectSettings *projectSettings;
	
	NSManagedObjectContext *context;

	
	// Context Menus + Popup Buttons
	IBOutlet NSMenu* regionMenu;
	IBOutlet NSMenu* arrangerMenu;
	IBOutlet id nudgeAmountMenu;
	IBOutlet id verticalGridModeMenu;
	IBOutlet id horizontalGridModeMenu;
	IBOutlet id horizontalGridAmountMenu;

	IBOutlet id arrangerDisplayModePopupButton;

	// regions
	NSMutableArray *placeholderRegions;
	NSArray *audioRegions;
		
	// selection
	NSMutableSet *selectedRegions;
	NSMutableSet *tempSelectedRegions;
	Region *hitRegion;
	
	id RegionForSelectedTrajectories;
	NSMutableSet *selectedTrajectories;

	// properties
	NSUInteger arrangerSizeX, arrangerSizeY;
	NSMutableIndexSet *arrangerTabStops;

	// mouse actions
	ArrangerEditMode arrangerEditMode;
	int dragging;
	float draggingParameter[4];
	NSPoint storedEventLocation;

	MarqueeView *marqueeView;
	
	int horizontalGridAmount;
	NSBezierPath *verticalGridPath, *horizontalGridPath;
	

	float zoomFactorX, zoomFactorY;
}

- (void)setup;
- (void)recalculateHorizontalGridPath;
- (void)recalculateVerticalGridPath;
- (void)recalculateArrangerProperties;
- (void)recalculateArrangerSize;

// dragging from pool
- (void)trajectoryDraggingUpdated:(id <NSDraggingInfo>)info;
- (void)audioDraggingUpdated:(id <NSDraggingInfo>)info;
- (BOOL)performTrajectoryDragOperation:(id <NSDraggingInfo>)info;
- (BOOL)performAudioDragOperation:(id <NSDraggingInfo>)info;


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
- (void)showSelectionRectangle:(NSEvent *)event;

// actions
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
- (IBAction)trim:(id)sender;
- (IBAction)split:(id)sender;
- (IBAction)heal:(id)sender;

// notifications
- (void)setZoom:(NSNotification *)notification;
- (void)update:(NSNotification *)notification;
- (void)undoNotification:(NSNotification *)notification;

@end