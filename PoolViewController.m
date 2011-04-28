//
//  PoolViewController.m
//  Choreographer
//
//  Created by Philippe Kocher on 26.06.09.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "CHGlobals.h"
#import "CHProjectDocument.h"
#import "AudioItem.h"
#import "AudioFile.h"
#import "AudioRegion.h"
#import "PoolViewController.h"
#import "PoolViews.h"
#import "TrajectoryInspectorWindowController.h"
#import "SettingsMenu.h"
#import "ImageAndTextCell.h"
#import "Path.h"


@implementation PoolViewController

+ (PoolViewController *)poolViewControllerForDocument:(NSPersistentDocument *)document
{
	PoolViewController *instance = [[[self alloc] initWithNibName:@"Pool" bundle:nil] autorelease];
	[instance setValue:document forKey:@"document"];
	
	return instance;
}


- (void) dealloc
{
	NSLog(@"PoolViewController: dealloc");
	[projectSettings release];	
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[super dealloc];
}

- (void)awakeFromNib
{
	// get stored settings
	projectSettings = [[document valueForKey:@"projectSettings"] retain];
	[tabControl setSelectedSegment:[[projectSettings valueForKey:@"poolSelectedTab"] intValue]];	
	[tabView selectTabViewItemAtIndex:[[projectSettings valueForKey:@"poolSelectedTab"] intValue]];
	
	// make userOutlineView and tableView appear with gradient selection, and behave like the Finder, iTunes, etc.
	[userOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	[audioItemTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	[trajectoryTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	// set background color
	NSColor *background = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:1.0];

	[userOutlineView setBackgroundColor:background];
	[audioItemTableView setBackgroundColor:background];
	[trajectoryTableView setBackgroundColor:background];
	
	[[audioItemTableView tableColumnWithIdentifier: @"audioItem"] setDataCell: [[ImageAndTextCell alloc] init]];
	[[trajectoryTableView tableColumnWithIdentifier: @"trajectoryItem"] setDataCell: [[ImageAndTextCell alloc] init]];

	// initialise context menu
	[dropOrderMenu setModel:projectSettings key:@"poolDropOrder"];
	
	// register for drag and drop
    [userOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:CHAudioItemType, CHTrajectoryType, CHFolderType, NSFilenamesPboardType, nil]];
    [audioItemTableView registerForDraggedTypes:[NSArray arrayWithObjects:CHAudioItemType, NSFilenamesPboardType, nil]];
    [trajectoryTableView registerForDraggedTypes:[NSArray arrayWithObjects: CHTrajectoryType, nil]];

	// double click behaviour
	[userOutlineView setDoubleAction:@selector(doubleClick:)];
	[userOutlineView setTarget:self];
	[audioItemTableView setDoubleAction:@selector(doubleClick:)];
	[audioItemTableView setTarget:self];
	[trajectoryTableView setDoubleAction:@selector(doubleClick:)];
	[trajectoryTableView setTarget:self];

	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refresh:)
												 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
}

- (void)setup
{
	// get stored data
	NSManagedObjectContext *context = [document managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSError *error;
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TrajectoryItem" inManagedObjectContext:context];
	
	[request setEntity:entityDescription];
	[request setReturnsObjectsAsFaults:NO];
	[context executeFetchRequest:request error:&error];
}	


#pragma mark -
#pragma mark IB actions
// -----------------------------------------------------------

- (IBAction)poolAddFolder:(id)sender
{
	NSArray *selected = [treeController selectedObjects];
	
	NSManagedObject *parentNode = nil;

	if([selected count] != 0)
	{
		NSManagedObject *selectedNode = [[treeController selectedObjects] objectAtIndex:0];
		if(![selectedNode valueForKey:@"isLeaf"])
		{
			parentNode = selectedNode;
		}
		else if([selectedNode valueForKey:@"parent"])
		{
			parentNode = [selectedNode valueForKey:@"parent"];
		}
	}

	NSManagedObject *newGroup = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[document managedObjectContext]];
	[newGroup setValue:parentNode forKey:@"parent"]; 
	[newGroup setValue:@"Untitled Folder" forKey:@"name"];
	[newGroup setValue:CHFolderType forKey:@"type"];
	[newGroup setValue:[NSNumber numberWithBool:NO] forKey:@"isLeaf"];
}

- (IBAction)importAudioFiles:(id)sender
{
	// choose audio file in an open panel
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setTreatsFilePackagesAsDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
	[openPanel setAllowedFileTypes:[AudioFile allowedFileTypes]];

	// 10.5.
	/*
	if([openPanel runModalForTypes:fileTypes] == NSOKButton)
	{
		[openPanel orderOut:self]; // close panel before we might present an error
		[self openAudioFiles:[openPanel filenames]];
	}
	*/
	
	[openPanel beginSheetModalForWindow:[document windowForSheet] completionHandler:^(NSInteger result)
	{
        if (result == NSOKButton)
		{
            [openPanel orderOut:self]; // close panel before we might present an error
            for(NSURL *url in [openPanel URLs])
			{
				[self importFile:url];
			}
        }
    }];
	

	if([[projectSettings valueForKey:@"poolSelectedTab"] intValue] == 2) // trajectory view
	{
		[tabControl setSelectedSegment:1];	
		[tabView selectTabViewItemAtIndex:1];		
	}
}

- (IBAction)newTrajectory:(id)sender
{	
	regionsForNewTrajectoryItem = nil;
	[self newTrajectoryItem:@"untitled"];
	
	if([[projectSettings valueForKey:@"poolSelectedTab"] intValue] == 1) // audio items view
	{
		[tabControl setSelectedSegment:2];	
		[tabView selectTabViewItemAtIndex:2];		
	}

	
//		[userOutlineView deselectAll:nil];
//		[audioItemTableView deselectAll:nil];
//		[trajectoryTableView deselectAll:nil];
		
// todo: select new trajectory

}

- (IBAction)deleteSelected:(id)sender
{
	NSEnumerator *nodeEnumerator;
	id node;
	BOOL dirty = NO;
	
	switch ([[projectSettings valueForKey:@"poolSelectedTab"] intValue])
	{
		case 0: // user view
			nodeEnumerator = [[treeController selectedObjects] objectEnumerator];
			break;
		case 1: // audio items view
			nodeEnumerator = [[audioItemArrayController selectedObjects] objectEnumerator];
			break;
		case 2: // trajectory view
			nodeEnumerator = [[trajectoryArrayController selectedObjects] objectEnumerator];
			break;
		default:
			nodeEnumerator = nil;
			break;
	}
	
	
	while (node = [nodeEnumerator nextObject])
	{
		if ([self recursivelyDeleteNode:node])
			dirty = YES;
	}
	
	if(dirty)
		[[[document managedObjectContext] undoManager] setActionName:@"delete"];

}

- (IBAction)renameSelected:(id)sender
{

}


// tab to change between views
- (IBAction)poolTab:(id)sender
{
	// update preferences
//	[[[document managedObjectContext] undoManager] disableUndoRegistration];
	[projectSettings setValue:[NSNumber numberWithInt:[sender selectedSegment]] forKey:@"poolSelectedTab"];
//	[[document managedObjectContext] processPendingChanges];
//	[[[document managedObjectContext] undoManager] enableUndoRegistration];
	
	[tabView selectTabViewItemAtIndex:[sender selectedSegment]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([item action] == @selector(poolAddFolder:) && [[projectSettings valueForKey:@"poolSelectedTab"] intValue] != 0)
		return NO;
	else
		return YES;
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)doubleClick:(id)sender
{
	// set selection to one single item and send show inspector
	if([sender isKindOfClass:[PoolOutlineView class]])
	{
		[treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:[sender clickedRow]]];
		
		id item = [[[treeController selectedObjects] objectAtIndex:0] valueForKey:@"item"];
		
		if([item isKindOfClass:[TrajectoryItem class]])
		{
			[[TrajectoryInspectorWindowController sharedTrajectoryInspectorWindowController] showInspectorForTrajectoryItem:item];
		}
	}
}

- (AudioItem *)importFile:(NSURL *)absoluteFilePath
{
	// take the selectetd group node (if any) as parent node
	NSManagedObject *parentNode = nil;
	if([[treeController selectedObjects] count])
	{
		NSManagedObject *selectedNode = [[treeController selectedObjects] objectAtIndex:0];
		if([selectedNode valueForKey:@"isLeaf"] == [NSNumber numberWithBool:NO])
		{
			parentNode = selectedNode;
		}
	}
	
	// get file path
	NSString *relativeFilePath = [Path path:absoluteFilePath relativeTo:[document fileURL]];
	NSString *filePath = [[NSURL URLWithString:relativeFilePath relativeToURL:[document fileURL]] path];

//	NSLog(@"**document: %@", [document fileURL]);
//	NSLog(@"**file: %@", absoluteFilePath);
//	NSLog(@"**relative: %@", relativeFilePath);
//	NSLog(@"**absolute: %@", filePath);

	
	// check if this audioFile already exists in data model
	NSManagedObjectContext *context = [document managedObjectContext];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"AudioItem" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(isOriginal == YES) AND (audioFile.relativeFilePath == %@)", relativeFilePath]];
	NSError *error;
	NSArray *audioItemsArray = [context executeFetchRequest:request error:&error];
		

	if([audioItemsArray count]) // duplicate
	{
		return [audioItemsArray objectAtIndex:0];
	}		

	// insert audio file, node and audio item
	AudioFile *newAudioFile = [NSEntityDescription insertNewObjectForEntityForName:@"AudioFile"
															inManagedObjectContext:context]; 
	NSManagedObject *newNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node"
															 inManagedObjectContext:context];
	AudioItem *newAudioItem = [NSEntityDescription insertNewObjectForEntityForName:@"AudioItem"
															inManagedObjectContext:context]; 
	
	
	
	// get filename from path
	NSString *theName = [filePath lastPathComponent];
	
	
	// set attributes and relationships
	
	[newAudioFile setValue:relativeFilePath forKey:@"relativeFilePath"];
	[newAudioFile setValue:[NSSet setWithObject:newAudioItem] forKey:@"audioItems"];
	
	[newNode setValue:parentNode forKey:@"parent"]; 
	[newNode setValue:[NSNumber numberWithBool:YES] forKey:@"isLeaf"];				
	[newNode setValue:theName forKey:@"name"];
	[newNode setValue:CHAudioItemType forKey:@"type"];
	[newNode setValue:newAudioItem forKey:@"item"];
	
	[newAudioItem setValue:newNode forKey:@"node"];
	[newAudioItem setValue:newAudioFile forKey:@"audioFile"];
	[newAudioItem setValue:[NSNumber numberWithBool:YES] forKey:@"isOriginal"];
	
	if(![newAudioFile openAudioFile])
	{
		// if opening the audio file wasn't successful delete the objects
		[context deleteObject:newAudioFile];
		[context deleteObject:newNode];
		[context deleteObject:newAudioItem];
	}
	else
	{
		// for newly imported audio files:
		// audio item has original length
		[newAudioItem setValue:[newAudioFile valueForKey:@"duration"] forKey:@"duration"];
		
		// expand parent node
		//				[userOutlineView expandItem:parentNode];
		// select the new item
		//[userOutlineView adaptSelection:[NSSet setWithObject:newNode]];
		[[userOutlineView window] makeFirstResponder:userOutlineView];
		
		[[[document managedObjectContext] undoManager] setActionName:@"import audio"];
	}

	[(UserTreeController *)treeController updateSortIndex];
	
	return newAudioItem;
}


- (void)newTrajectoryItem:(NSString *)name
{
	// show the new trajectory sheet
	
	[self setValue:name forKey:@"newTrajectoryName"];	
	[self setValue:[NSNumber numberWithInt:0] forKey:@"newTrajectoryType"];
	
	[NSApp beginSheet:newTrajectorySheet
	   modalForWindow:[[self view] window]
		modalDelegate:self
	   didEndSelector:@selector(newTrajectorySheetDidEnd: returnCode: contextInfo:)
		  contextInfo:nil];
}

- (void)newTrajectorySheetOK
{
	[NSApp endSheet:newTrajectorySheet returnCode:NSOKButton];
	[newTrajectorySheet orderOut:nil];
}

- (void)newTrajectorySheetCancel;
{
	[NSApp endSheet:newTrajectorySheet returnCode:NSCancelButton];
	[newTrajectorySheet orderOut:nil];
}

- (void)newTrajectorySheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSCancelButton)
	{
		return;
	}
	
	NSManagedObject *parentNode = nil;
	NSTreeNode *selectedTreeNode = nil;
	
	if([[projectSettings valueForKey:@"poolSelectedTab"] intValue] == 0) // user view
	{
		// get (last) selected item
		NSIndexSet *selectedIndices = [userOutlineView selectedRowIndexes];
		selectedTreeNode = [userOutlineView itemAtRow:[selectedIndices lastIndex]];
		NSManagedObject *selectedNode = [selectedTreeNode representedObject];

		if([selectedIndices count] == 1 && ![[selectedNode valueForKey:@"isLeaf"] boolValue])
		{
			// the only selected item is a group
			parentNode = selectedNode;
		}
		else
		{
			// insert as sibling of the last selected item
			parentNode = [selectedNode valueForKey:@"parent"];
		}
	}
	
	
	// check if the name is unique
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TrajectoryItem" inManagedObjectContext:[document managedObjectContext]];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"node.name == %@", newTrajectoryName]];
	NSError *error;
	NSString *newName = [newTrajectoryName copy];
	
	if([[document managedObjectContext] countForFetchRequest:request error:&error])
	{
		BOOL unique = NO;
		int i;
		
		for(i=1;!unique;i++)
		{
			[request setPredicate:[NSPredicate predicateWithFormat:@"node.name == %@", [newTrajectoryName stringByAppendingString:[NSString stringWithFormat:@" %i", i]]]];
			
			if([[document managedObjectContext] countForFetchRequest:request error:&error] == 0)
			{
				newName = [newTrajectoryName stringByAppendingString:[NSString stringWithFormat:@" %i", i]];
				unique = YES;
			}
		}
	}
	
	// insert trajectory item in model
	NSManagedObject *newNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node"
															 inManagedObjectContext:[document managedObjectContext]];
	TrajectoryItem *newItem = [NSEntityDescription	insertNewObjectForEntityForName:@"TrajectoryItem"
															inManagedObjectContext:[document managedObjectContext]]; 
	
	[newNode setValue:parentNode forKey:@"parent"]; 
	[newNode setValue:newName forKey:@"name"];
	[newNode setValue:CHTrajectoryType forKey:@"type"];
	[newNode setValue:newItem forKey:@"item"];

	[newItem setValue:[NSNumber numberWithInt:newTrajectoryType] forKey:@"trajectoryType"];
	[newItem setValue:regionsForNewTrajectoryItem forKey:@"regions"];
	
	// store data
	[newItem archiveData];
	
	// undo
	[[[document managedObjectContext] undoManager] setActionName:@"new trajectory"];
	
	// expand group
	[userOutlineView expandItem:selectedTreeNode];
	
	// todo: select the new trajectory
}

- (BOOL)recursivelyDeleteNode:(id)node
{		
	NSEnumerator *nodeEnumerator;
	id subnode;
	BOOL dirty = NO;
	BOOL groupIsEmpty = YES;
	Region *region;
	
	// node is a group (folder)
	if([[node mutableSetValueForKeyPath:@"children"] count])
	{
		nodeEnumerator = [[node mutableSetValueForKeyPath:@"children"] objectEnumerator];
		
		while (subnode = [nodeEnumerator nextObject])
		{
			BOOL flag = [self recursivelyDeleteNode:subnode];
			
			if(flag)
				dirty = YES;
			
			if(!flag)
				groupIsEmpty = NO;
		}
		
		if(groupIsEmpty)
			[[document managedObjectContext] deleteObject:node];
		
		return dirty;
	}
	
	// node is a single item
	NSString *name = [node valueForKey:@"name"]; 

	if([[node valueForKey:@"type"] isEqualToString:CHAudioItemType])
	{
		NSSet *regions = [node mutableSetValueForKeyPath:@"item.audioRegions"];
	
		if([regions count])
		{		
			NSAlert *alert = [NSAlert alertWithMessageText:@"Delete Audio?"
											 defaultButton:@"Cancel"
										   alternateButton:@"Delete"
											   otherButton:nil
								 informativeTextWithFormat:[NSString stringWithFormat:@"\"%@\" is used on the timeline. Do you want to delete it?", name]];
			
			// show alert in a modal dialog
			if ([alert runModal] == NSAlertDefaultReturn)
			{
				return NO;
			}
			
			// remove all regions from arrangerView
			for (region in regions)
			{
				[region removeFromView];
			}
		}
								
		// delete audio file if it isn't referenced anymore
		AudioFile *audioFile = [node valueForKeyPath:@"item.audioFile"];

		if([[audioFile valueForKey:@"audioItems"] count] == 1 && [node valueForKey:@"item"] == [[audioFile valueForKey:@"audioItems"] anyObject])
		{
			// NSLog(@"delete audioFile %@", audioFile);
			[[document managedObjectContext] deleteObject:audioFile];
		}
	}
	else if([[node valueForKey:@"type"] isEqualToString:CHTrajectoryType])
	{
		NSSet *regions = [node mutableSetValueForKeyPath:@"item.regions"];

		if([regions count])
		{
			NSAlert *alert = [NSAlert alertWithMessageText:@"Delete Trajectory?"
											 defaultButton:@"Cancel"
										   alternateButton:@"Delete"
											   otherButton:nil
								 informativeTextWithFormat:[NSString stringWithFormat:@"\"%@\" is used on the timeline. Do you want to delete it?", name]];
			
			// show alert in a modal dialog
			if ([alert runModal] == NSAlertDefaultReturn)
			{
				return NO;
			}

			// nullify relations to regions
			for (region in regions)
			{
				[region setValue:NULL forKey:@"trajectoryItem"];
			}
		}
	}
	else
	{
		return NO;
	}

	[[document managedObjectContext] deleteObject:node];
	
	return YES;
}

#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------


// binding in IB
- (NSManagedObjectContext *)managedObjectContext
{
	return [document managedObjectContext];
}


#pragma mark -
#pragma mark selection
// -----------------------------------------------------------

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if ([[[notification object] valueForKey:@"hasFocus"] boolValue])
	{
		[(CHProjectDocument *)document selectionInPoolDidChange];
		//NSLog(@"poolOutlineView: selection did change");	
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([[[notification object] valueForKey:@"hasFocus"] boolValue])
	{
		[(CHProjectDocument *)document selectionInPoolDidChange];
		//NSLog(@"poolTableView: selection did change");	
	}
}

- (void)adaptSelection:(NSSet *)selectedAudioRegions
{
	[userOutlineView deselectAll:nil];
	[audioItemTableView deselectAll:nil];
	[trajectoryTableView deselectAll:nil];
	
	NSEnumerator *enumerator = [selectedAudioRegions objectEnumerator];
	AudioRegion *region;
	NSMutableSet *selectedAudioItems = [[[NSMutableSet alloc] init] autorelease];
	
	while(region = [enumerator nextObject])
	{
		if([region isKindOfClass:[AudioRegion class]])
		   [selectedAudioItems addObject:[region valueForKey:@"audioItem"]];
	}
	
	NSMutableIndexSet *selectedIndices = [[[NSMutableIndexSet alloc] init] autorelease];
	NSArray *arrangedObjects = [audioItemArrayController arrangedObjects];
	enumerator = [arrangedObjects objectEnumerator];
	NSManagedObject *node;
	
	while(node = [enumerator nextObject])
	{
		if([selectedAudioItems containsObject:[node valueForKey:@"item"]])
		{
			[selectedIndices addIndex:[arrangedObjects indexOfObject:node]];
		}
	}

	[audioItemTableView selectRowIndexes:selectedIndices byExtendingSelection:NO];
}


- (NSArray *)selectedTrajectories
{
	NSMutableArray *selectedTrajectories = [[[NSMutableArray alloc] init] autorelease];
	NSEnumerator *enumerator;
	id object;
	id item;
		
	switch([[projectSettings valueForKey:@"poolSelectedTab"] intValue])
	{	
		case 0:
			enumerator = [[treeController selectedObjects] objectEnumerator];
			break;
			
		case 2:
			enumerator = [[trajectoryArrayController selectedObjects] objectEnumerator];
			break;
			
		default:
			return nil;
	}
			
	while ((object = [enumerator nextObject]))
	{
		if([[object valueForKey:@"type"] isEqualToString:CHAudioItemType])
		{
			return nil;
		}
		else if([[object valueForKey:@"type"] isEqualToString:CHTrajectoryType] && [[object valueForKey:@"isLeaf"] boolValue])
		{
			item = [object valueForKey:@"item"];
			[item willAccessValueForKey:nil]; // fire fault
			[selectedTrajectories addObject:item];
		}
	}

	return selectedTrajectories;
}

#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)refresh:(NSNotification *)notification
{
	NSDictionary *info = [notification userInfo];
	
	for(id object in [info objectForKey:NSInsertedObjectsKey])
	{		
		if([object isKindOfClass:[AudioItem class]] ||
		   [object isKindOfClass:[TrajectoryItem class]])
		{
			[audioItemArrayController fetch:NULL];
			[trajectoryArrayController fetch:NULL];
			return;
		}
	}

	for(id object in [info objectForKey:NSDeletedObjectsKey])
	{		
		if([object isKindOfClass:[AudioItem class]] ||
		   [object isKindOfClass:[TrajectoryItem class]])
		{
			[audioItemArrayController fetch:NULL];
			[trajectoryArrayController fetch:NULL];
			return;
		}
	}
}


#pragma mark -
#pragma mark etc...
// -----------------------------------------------------------

- (NSString *)nodeImageName:(id)node
{
	/* depending on the type return the appropriate image */
	if([node valueForKey:@"isLeaf"] == [NSNumber numberWithBool:NO])
		return @"folder";
	
	if([[node valueForKey:@"type"] isEqualToString:CHAudioItemType])
		return @"audioItem";

	else
		return @"trajectoryItem";
}

- (NSColor *)nodeTextColor:(id)node
{
	/* return the appropriate color */
	if([[node valueForKey:@"type"] isEqualToString:CHAudioItemType] && 
	   ![[node valueForKeyPath:@"item.audioFile"] audioFileID])
		return [NSColor grayColor];
	
	else
		return [NSColor blackColor];
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	// We know that the cell at this column is our image and text cell
	ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
	NSImage *image = [NSImage imageNamed:[self nodeImageName:[item representedObject]]];
	[imageAndTextCell setImage:image];

	[imageAndTextCell setTextColor:[self nodeTextColor:[item representedObject]]];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tc row:(NSInteger)row
{
	ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
	NSImage *image = [NSImage imageNamed:[tc identifier]];
	[imageAndTextCell setImage:image];
	
	if([[tc identifier] isEqualToString:@"audioItem"] && ![[[[audioItemArrayController arrangedObjects] objectAtIndex:row] valueForKeyPath:@"item.audioFile"] audioFileID])
		[imageAndTextCell setTextColor:[NSColor grayColor]];
	else
		[imageAndTextCell setTextColor:[NSColor blackColor]];
		
}

#pragma mark -
#pragma mark pool drag and drop
// -----------------------------------------------------------
/*
	drag and drop only with one item at a time
	(multiple selection NOT selected in IB)
*/

- (NSArray *)treeNodeSortDescriptors;
{
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES] autorelease]];
}

/*
    Beginning the drag from the outline view.
*/
#define PoolPboardType @"PoolPboardType"

- (BOOL)outlineView:(NSOutlineView *)poolView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	// Type
//	NSString *type = [[[items objectAtIndex:0] representedObject] valueForKey:@"type"];
//	if(!type) type = CHFolderType;
	
    draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.

	[pboard declareTypes:[NSArray arrayWithObjects:PoolPboardType, /* NSFilesPromisePboardType, */ nil] owner:self];

	// Query the NSTreeNode (not the underlying Core Data object) for its index path under the tree controller.
//	NSIndexPath *pathToDraggedNode = [[items objectAtIndex:0] indexPath];
	
	// Place the index path on the pasteboard.
//	NSData *indexPathData = [NSKeyedArchiver archivedDataWithRootObject:pathToDraggedNode];
//	[pboard setData:indexPathData forType:type];

    // the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
    [pboard setData:[NSData data] forType:[[[items objectAtIndex:0] representedObject] valueForKey:@"type"]]; 
	[pboard setData:[NSData data] forType:PoolPboardType]; 

	// set draggedItems (dragging to arranger view)
	NSEnumerator *enumerator = [items objectEnumerator];
	id item;
	NSMutableArray *tempAudioArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempTrajectoryArray = [[[NSMutableArray alloc] init] autorelease];
 
	while (item = [enumerator nextObject])
	{
		if([[[item representedObject] valueForKey:@"type"] isEqualToString:CHAudioItemType])
			[tempAudioArray addObject:[item representedObject]];
		else if([[[item representedObject] valueForKey:@"type"] isEqualToString:CHTrajectoryType])
			[tempTrajectoryArray addObject:[item representedObject]];
	}
	
	[document setValue:[NSArray arrayWithArray:tempAudioArray] forKey:@"draggedAudioRegions"];
	[document setValue:[NSArray arrayWithArray:tempTrajectoryArray] forKey:@"draggedTrajectories"];

    // Return YES so that the drag actually begins...
    return YES;
}

/*
 Validating a drop in the outline view.
 */
- (NSDragOperation)outlineView:(NSOutlineView *)poolView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
    NSTreeNode *targetNode = item;
	BOOL dropIsValid = YES;
	
	// Refuse if dropping "on" the outline view itself
	if (targetNode == nil && childIndex == NSOutlineViewDropOnItemIndex)
	    dropIsValid = NO;

	// Refuse if proposed item is not group/folder
	if([[[item representedObject] valueForKey:@"isLeaf"] boolValue])
	{
		dropIsValid = NO;
	}
	
	// Check to make sure we don't allow a node to be inserted into one of its descendants!
	if (dropIsValid && [info draggingSource] == userOutlineView && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject: PoolPboardType]] != nil)
	{
	    NSArray *_draggedNodes = [(NSObject *)[[info draggingSource] dataSource] valueForKey:@"draggedNodes"];
	    dropIsValid = ![self treeNode:targetNode isDescendantOfNodeInArray: _draggedNodes];
	}
	
	return dropIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}

- (BOOL)treeNode:(NSTreeNode *)aNode isDescendantOfNodeInArray:(NSArray *)nodes
{
    // returns YES if any 'node' in the array 'nodes' is an ancestor of 'aNode'.
	
    NSEnumerator *nodeEnumerator = [nodes objectEnumerator];
    NSTreeNode *node = nil;
	
    while ((node = [nodeEnumerator nextObject]))
	{
		NSTreeNode *parent = aNode;
		while (parent) {
			if (parent == node) return YES;
			parent = [parent parentNode];
		}
    }
    return NO;
}


/*
    Performing a drop in the outline view. This allows the user to manipulate the structure of the tree by moving subtrees under new parent nodes.
*/
- (BOOL)outlineView:(NSOutlineView *)poolView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{	
	NSLog(@"item %@", item);
	NSLog(@"childIndex %d", index);
	NSLog(@"draggingPasteboard %@", [[info draggingPasteboard] dataForType:PoolPboardType]);

	index = index == NSOutlineViewDropOnItemIndex ? 0 : index;

	// Retrieve the index path from the pasteboard.
	if([[info draggingPasteboard] dataForType:PoolPboardType])
	{	
		if(!item)
			[treeController moveNodes:draggedNodes toIndexPath:[NSIndexPath indexPathWithIndex:index]];
		else
			[treeController moveNodes:draggedNodes toIndexPath:[[item indexPath] indexPathByAddingIndex:index]];
	}
	else
	{
		// a file dragged from the finder
		for(NSString *path in [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType])
		{
			[self importFile:[NSURL URLWithString:path]];
		}
	}
    return YES;
/*	
	
	NSIndexPath *droppedIndexPath;
	

	
	// Retrieve the index path from the pasteboard.
	if([[info draggingPasteboard] dataForType:CHAudioItemType])
	{
		droppedIndexPath = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:CHAudioItemType]];
	}
	else if([[info draggingPasteboard] dataForType:CHTrajectoryType])
	{
		droppedIndexPath = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:CHTrajectoryType]];
	}
	else if([[info draggingPasteboard] dataForType:CHFolderType])
	{
		droppedIndexPath = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:CHFolderType]];
	}
	else
	{
		[self openAudioFiles:[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType]];
		return YES;
	}
	
	// We need to find the NSTreeNode positioned at the index path. We start by getting the root node of the tree.
	// In NSTreeController, arrangedObjects returns the root node of the tree.
	id treeRoot = [treeController arrangedObjects];

	// Find the node being moved by querying the root node.
	NSTreeNode *node = [treeRoot descendantNodeAtIndexPath:droppedIndexPath];

	// Use the tree controller to move the node. This will manage any changes necessary in the parent-child relationship.
	// modeNode:toIndex:Path is a 10.5 API addition to NSTreeController.
	if(item) // dragged onto a group
	{
		index = index < 0 ? 0 : index;
		[treeController moveNode:node toIndexPath:[[item indexPath] indexPathByAddingIndex:index]];
	}
	else
		[treeController moveNode:node toIndexPath:[NSIndexPath indexPathWithIndex:index]];

	// Return YES so that the user gets visual feedback that the drag was successful...
	return YES;
*/
}

@end


#pragma mark -
// -----------------------------------------------------------

@implementation UserTreeController

- (void)insertObject:(id)object atArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
	[super insertObject:object atArrangedObjectIndexPath:indexPath];
	[self updateSortIndex];
}

- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
	[super insertObjects:objects atArrangedObjectIndexPaths:indexPaths];
	[self updateSortIndex];
}

- (void)removeObjectAtArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
	[super removeObjectAtArrangedObjectIndexPath:indexPath];
	[self updateSortIndex];
}

- (void)removeObjectsAtArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
	[super removeObjectsAtArrangedObjectIndexPaths:indexPaths];
	[self updateSortIndex];
}

- (void)moveNode:(NSTreeNode *)node toIndexPath:(NSIndexPath *)indexPath;
{
	[super moveNode:node toIndexPath:indexPath];
	[self updateSortIndex];	
}

- (void)moveNodes:(NSArray *)nodes toIndexPath:(NSIndexPath *)indexPath;
{
	[super moveNodes:nodes toIndexPath:indexPath];
	[self updateSortIndex];
}


/*	iterate through all tree nodes 
	take the index path and set its last index as the sort index
*/ 
- (void)updateSortIndex
{
	NSIndexPath *indexPath;
	
	for (NSTreeNode *node in [[self arrangedObjects] childNodes])
	{
		indexPath = [node indexPath];
		[[node representedObject] setValue:[NSNumber numberWithInt:[indexPath indexAtPosition:[indexPath length] - 1]] forKey:@"sortIndex"];
	}
}

@end


#pragma mark -
// -----------------------------------------------------------


@implementation AudioItemArrayController

- (BOOL)fetchWithRequest:(NSFetchRequest *)fetchRequest merge:(BOOL)merge error:(NSError **)error
{
	NSLog(@"a fetchWithRequest");
    // set predicate
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", CHAudioItemType];
    [fetchRequest setPredicate:predicate];

	// set sort descriptor
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
	return [super fetchWithRequest:fetchRequest merge:merge error:error];
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObject:CHAudioItemType] owner:self];
	
	NSMutableIndexSet *selection = [NSMutableIndexSet indexSetWithIndex:[rowIndexes firstIndex]];
	if([rowIndexes count] > 1)
	{
		[selection addIndexes:[self selectionIndexes]];
	}

	[self setSelectionIndexes:selection];
	
	[[[NSDocumentController sharedDocumentController] currentDocument] setValue:[self selectedObjects] forKey:@"draggedAudioRegions"];
	[[[NSDocumentController sharedDocumentController] currentDocument] setValue:nil forKey:@"draggedTrajectories"];
	
    // Return YES so that the drag actually begins...
    return YES;
}


@end

#pragma mark -

@implementation TrajectoryArrayController

- (BOOL)fetchWithRequest:(NSFetchRequest *)fetchRequest merge:(BOOL)merge error:(NSError **)error
{
	NSLog(@"t fetchWithRequest");
    // set predicate
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", CHTrajectoryType];
    [fetchRequest setPredicate:predicate];

	// set sort descriptor
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    return [super fetchWithRequest:fetchRequest merge:merge error:error];
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObject:CHTrajectoryType] owner:self];
	
	NSMutableIndexSet *selection = [NSMutableIndexSet indexSetWithIndex:[rowIndexes firstIndex]];
	if([rowIndexes count] > 1)
	{
		[selection addIndexes:[self selectionIndexes]];
	}

	[self setSelectionIndexes:selection];
	
	[[[NSDocumentController sharedDocumentController] currentDocument] setValue:[self selectedObjects] forKey:@"draggedTrajectories"];
	[[[NSDocumentController sharedDocumentController] currentDocument] setValue:nil forKey:@"draggedAudioRegions"];
	
    // Return YES so that the drag actually begins...
    return YES;
}


@end

