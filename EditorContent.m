//
//  EditorContent.m
//  Choreographer
//
//  Created by Philippe Kocher on 05.11.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "EditorContent.h"
#import "CHProjectDocument.h"
#import "AudioRegion.h"

static EditorContent *sharedEditorContent = nil;

@implementation EditorContent

+ (id)sharedEditorContent
{
    if (!sharedEditorContent)
	{
        sharedEditorContent = [[EditorContent alloc] init];
    }

    return sharedEditorContent;
}

- (id)init
{
	if(self = [super init])
	{
		editorSelection = [[NSMutableSet alloc] init];
		displayMode = noDisplayMode;
		infoString = [[NSMutableString alloc] init];
		
		[[NSUserDefaults standardUserDefaults] addObserver:self
												forKeyPath:@"editorContentMode"
												   options:0
												   context:NULL];
	}

	return self;
}

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self
											   forKeyPath:@"editorContentMode"];
	
	[selectedAudioRegions release];
	[allAudioRegions release];
	[displayedAudioRegions release];
	
	[displayedTrajectories release];
	
	[editorSelection release];
	[infoString release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self setDisplayedItems];
}

- (void)synchronizeWithArranger:(id)arranger pool:(id)pool
{
	// clear the editors' selection
	[editorSelection removeAllObjects];
	editableTrajectory = nil;
	
	// get selected trajectories from pool
	[displayedTrajectories release];
	displayedTrajectories = [[pool valueForKey:@"selectedTrajectories"] retain];
	
	// get selected regions from arranger window
	[selectedAudioRegions release];
	selectedAudioRegions = [[[arranger valueForKey:@"selectedAudioRegions"] sortedArrayUsingDescriptors:nil] retain];
	
	// get all regions from arranger window
	[allAudioRegions release];
	allAudioRegions = [[[arranger valueForKey:@"audioRegions"] sortedArrayUsingDescriptors:nil] retain];
	

	// find the regions that are actually displayed
	[self setDisplayedItems];
	
}

- (void)synchronizeWithLocator:(unsigned long)value
{
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] == 0)
	{
		locator = value;
		[self setDisplayedItems];
	}
}

- (void)setDisplayedItems
{
	CHProjectDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
	NSString *projectName = [document displayName];
	
	if([selectedAudioRegions count])
	{
		displayMode = regionDisplayMode;
		[infoString setString:[NSString stringWithFormat:@"%@: selected regions", projectName]];
	}
	else if([displayedTrajectories count] && [[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] != 0)
	{
		displayMode = trajectoryDisplayMode;
		editableTrajectory = [displayedTrajectories objectAtIndex:0]; 
		[infoString setString:[NSString stringWithFormat:@"%@: selected trajectories", projectName]];
	}
	else
	{
		if([[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] == 0)
		{
			displayMode = regionDisplayMode;  //locatorDisplayMode;
			[infoString setString:[NSString stringWithFormat:@"%@: locator %ld", projectName, locator]];
		}
		else
		{
			displayMode = noDisplayMode;
			[infoString setString:[NSString stringWithFormat:@"%@: -", projectName]];
		}
	}
	
	if(!document)
	{
		[infoString setString:@"-"];
	}

	
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] == 0)
	{
		NSMutableArray *tempArray = [[[NSMutableSet alloc] init] autorelease];
		
		for(AudioRegion *region in allAudioRegions)
		{
			if([[region valueForKey:@"startTime"] longValue] <= locator &&
			   [[region valueForKey:@"startTime"] longValue] + [[region valueForKey:@"duration"] longValue] >= locator)
			{
				[tempArray addObject:region];
			}
		}
		
		[displayedAudioRegions release];
		displayedAudioRegions = [[NSArray arrayWithArray:tempArray] retain];
	}
	else
	{
		[displayedAudioRegions release];
		displayedAudioRegions = [selectedAudioRegions retain];
	}
	
	
	// update views
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:nil];
}

- (void)deleteSelectedPoints
{
	for(id breakpoint in editorSelection)
	{
		[editableTrajectory removeBreakpoint:breakpoint];
	}
	[editableTrajectory updateModel];
	
	[editorSelection removeAllObjects];
}

- (void)updateModelForSelectedPoints
{
	if(displayMode == regionDisplayMode)
	{
		NSEnumerator *enumerator;
		AudioRegion *region; 

		enumerator = [editorSelection objectEnumerator];
		while ((region = [enumerator nextObject]))
		{
			[region updatePositionInModel];
		}

		// undo
		NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
		if([editorSelection count] == 1)
			[[managedObjectContext undoManager] setActionName:@"region: edit spatial position"];
		else if([editorSelection count] > 1)
			[[managedObjectContext undoManager] setActionName:@"multiple regions: edit spatial position"];
	}
	else
	{
		[editableTrajectory updateModel];
	}
}

@end
