//
//  PoolViewController.h
//  Choreographer
//
//  Created by Philippe Kocher on 26.06.09.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TrajectoryItem.h"


@interface PoolViewController : NSViewController
{
	NSPersistentDocument *document;
    NSManagedObject *projectSettings;
	
	IBOutlet NSOutlineView *userOutlineView;
	IBOutlet NSTableView *audioItemTableView;
	IBOutlet NSTableView *trajectoryTableView;
	
	IBOutlet NSTreeController *treeController;
	IBOutlet NSArrayController *audioItemArrayController;
	IBOutlet NSArrayController *trajectoryArrayController;
	
	IBOutlet NSSegmentedControl *tabControl;
	IBOutlet NSTabView *tabView;
	
	// Context Menu
	IBOutlet NSMenu *contextMenu;
	IBOutlet id dropOrderMenu;

	// drag and drop
    NSArray *draggedNodes;
}

+ (PoolViewController *)poolViewControllerForDocument:(NSPersistentDocument *)document;

- (void)setup;

// IB actions
- (IBAction)poolAddFolder:(id)sender;
- (IBAction)importAudioFiles:(id)sender;
- (IBAction)newTrajectory:(id)sender;
- (IBAction)deleteSelected:(id)sender;
- (IBAction)renameSelected:(id)sender;
- (IBAction)poolTab:(id)sender;

// actions
- (void)openAudioFiles:(NSArray *)filenames;
- (TrajectoryItem *)newTrajectoryItem:(NSString *)name;
- (BOOL)recursivelyDeleteNode:(id)node;

// selection
- (void)adaptSelection:(NSSet *)selectedAudioRegions;
- (NSArray *)selectedTrajectories;

// notification
- (void)refresh:(NSNotification *)notification;


- (NSString *)nodeImageName:(id)item;
- (BOOL)treeNode:(NSTreeNode *)aNode isDescendantOfNodeInArray:(NSArray *)nodes;

@end


@interface UserTreeController : NSTreeController
- (void)updateSortIndex;

@end

@interface AudioItemArrayController : NSArrayController {}
@end

@interface TrajectoryArrayController : NSArrayController {}
@end

