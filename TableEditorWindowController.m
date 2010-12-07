//
//  TableEditorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 25.10.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "TableEditorWindowController.h"
//#import "TrajectoryItem.h"
#import "AudioRegion.h"
#import "Breakpoint.h"


static TableEditorWindowController *sharedTableEditorWindowController = nil;

@implementation TableEditorWindowController

+ (id)sharedTableEditorWindowController
{
    if (!sharedTableEditorWindowController)
	{
        sharedTableEditorWindowController = [[TableEditorWindowController alloc] init];
    }
    return sharedTableEditorWindowController;
}

- (id)init
{
	self = [self initWithWindowNibName:@"TableEditor"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"TableEditor"];
    }
    return self;
}


- (void) refreshView
{
	[tableEditorView reloadData];

	// hide name column for trajectories
	NSTableColumn *column = [tableEditorView tableColumnWithIdentifier:@"name"];
	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	
	if(displayMode == regionDisplayMode)
	{
		[column setHidden:NO];
		[column setEditable:NO];
	}
	else
	{
		[column setHidden:YES];
		[column setEditable:NO];
	}

	// selection
	NSMutableIndexSet *rowIndexes = [[[NSMutableIndexSet alloc] init] autorelease];

	NSEnumerator *enumerator = [[[EditorContent sharedEditorContent] valueForKey:@"editorSelection"] objectEnumerator];
	id item;
 
	while ((item = [enumerator nextObject]))
	{
		if(displayMode == regionDisplayMode)
			[rowIndexes addIndex:[[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] indexOfObject:item] + 1];
		else if(displayMode == trajectoryDisplayMode)
		{
			if([[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] linkedBreakpointArray])
				[rowIndexes addIndex:[[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] linkedBreakpointArray] indexOfObject:item] + 1];
		}
	}		
	[tableEditorView selectRowIndexes:rowIndexes byExtendingSelection:NO];
}

#pragma mark -
#pragma mark NSTableView - delegate methods
// -----------------------------------------------------------

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id selectedIndices = [tableEditorView selectedRowIndexes];
	id editorSelection = [[EditorContent sharedEditorContent] valueForKey:@"editorSelection"];
	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	id editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];

	[editorSelection removeAllObjects];

	int i = [selectedIndices firstIndex];
	
	if(i == 0) return;
		
	while(i != NSNotFound)
	{
		if(displayMode == regionDisplayMode)
			[editorSelection addObject:[[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] objectAtIndex:i - 1]];
		else if(displayMode == trajectoryDisplayMode && editableTrajectory)
			[editorSelection addObject:[[editableTrajectory linkedBreakpointArray] objectAtIndex:i - 1]];

		i = [selectedIndices indexGreaterThanIndex:i];
	}

	// update views
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
}


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tc row:(NSInteger)row;
{
	// draw background for title rows
	
	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];

	if(displayMode == regionDisplayMode)
	{
		[cell setDrawsBackground: (row == 0)];
		[cell setSelectable: (row != 0)];
		[cell setEditable: (row != 0)];
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		[cell setDrawsBackground: (row == 0)];
		[cell setSelectable: (row != 0)];
		[cell setEditable: (row != 0)];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)row
{
	NSLog(@"shouldSelectRow");

	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	id editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];

	if(displayMode == regionDisplayMode)
	{
		return (row != 0);
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		switch([[editableTrajectory valueForKey:@"trajectoryType"] intValue])
		{
			case breakpointType:
				return (row != 0);
				break;
			case rotationType:
				return (row != 0 && row != 2);
				break;
			case randomType:
				return (row != 0 && row != 2);
				break;
		}
	}

	return NO;
}

#pragma mark -
#pragma mark NSTableView - data source - global
// -----------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	int n, sum;

	if(displayMode == regionDisplayMode)
	{
		// plus 1: title row
		return [[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] count] + 1;
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		sum = 0;
		
		// linked breakpoints (if any) plus title row
		n = [[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] linkedBreakpointArray] count];
		if(n) sum += n + 1;
			
		// additional handles (if any) plus title row
		n = [[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] additionalPositions] count];
		if(n) sum += n + 1;
		
		// meta parameter (if any) plus title row
			
			
		return sum;
	}
	else return 0;
}


// Table view: getting values
// -----------------------------------------------------------

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(id)tc row:(NSInteger)row
{
	int displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	NSArray *displayedRegions = [[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"];
	id editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	SpatialPosition *pos;
	int n, sum;
	
	if(displayMode == regionDisplayMode)
	{
		if(row == 0)
		{
			if ([[tc identifier] isEqualToString:@"name"]) return @"Region";
			else if ([[tc identifier] isEqualToString:@"time"]) return @"Time";
			else return [tc identifier];
		}
		else
		{
			row--;
			
			if([[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] == 0)
			{
				pos = [[displayedRegions objectAtIndex:row] regionPositionAtTime:[[[EditorContent sharedEditorContent] valueForKey:@"locator"] longValue]];
			}
			else
			{
				pos = [[displayedRegions objectAtIndex:row] valueForKey:@"position"];
			}

			if ([[tc identifier] isEqualToString:@"name"])
				return [NSString stringWithFormat:@"%@", [[displayedRegions objectAtIndex:row] valueForKeyPath:@"audioItem.node.name"]];
			else if ([[tc identifier] isEqualToString:@"time"])
				return [NSString stringWithFormat:@"%0.3f", [[[displayedRegions objectAtIndex:row] valueForKey:@"startTime"] unsignedLongValue] * 0.001];
			else return [NSString stringWithFormat:@"%0.3f", [[pos valueForKey:[tc identifier]] floatValue]];
		}
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		sum = 0;
		// linked breakpoints (if any) plus title row
		n = [[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] linkedBreakpointArrayWithInitialPosition:nil] count];
		if(n)
		{
			if(row == sum)
			{
				if ([[tc identifier] isEqualToString:@"time"]) return @"Time";
				else return [tc identifier];
			}
			else
			{
				row -= sum + 1;
				
				id breakpoint = [[editableTrajectory linkedBreakpointArrayWithInitialPosition:nil] objectAtIndex:row];
				if ([[tc identifier] isEqualToString:@"time"])
				{
					return [NSNumber numberWithUnsignedLong:[[breakpoint valueForKey:@"time"] unsignedLongValue]];
				}
				else
				{
					if([[editableTrajectory valueForKey:@"adaptiveInitialPosition"] boolValue] && row == 0)
						return @">";
					else
						return [NSString stringWithFormat:@"%0.3f", [[breakpoint valueForKey:[tc identifier]] doubleValue]];
				}
			}
			sum += n + 1;
		}

		// additional positions (if any) plus title row
		n = [[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] additionalPositions] count];
		if(n)
		{			
			if(row == sum)
			{
				if ([[tc identifier] isEqualToString:@"time"]) return @"*";
				else return [tc identifier];
			}
			else
			{
				row -= sum + 1;
				
				id position = [[editableTrajectory additionalPositions] objectAtIndex:row];
				if ([[tc identifier] isEqualToString:@"time"])
				{
					return [editableTrajectory additionalPositionName:position];
				}
				else
				{
					return [NSString stringWithFormat:@"%0.3f", [[position valueForKey:[tc identifier]] doubleValue]];
				}
			}

			sum += n + 1;
		}
		
		
		
		
		
//		switch([[editableTrajectory valueForKey:@"trajectoryType"] intValue])
//		{
//			case breakpointType:
//				return [self breakpointTrajectory:editableTrajectory valueForTableColumn:tc row:row];
//				break;
//			case rotationType:
//				return [self rotationTrajectory:editableTrajectory valueForTableColumn:tc row:row];
//				break;
//			case randomType:
//				return [self randomTrajectory:editableTrajectory valueForTableColumn:tc row:row];
//				break;
//		}
	}
	return nil;
}

// Table view: setting values
// -----------------------------------------------------------

- (void)tableView:(NSTableView *)tv setObjectValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(NSInteger)row
{
	int displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	id displayedRegions = [[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"];
	id editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	
	if(displayMode == regionDisplayMode)
	{
		id pos = [[displayedRegions objectAtIndex:row - 1] valueForKey:@"position"];
		
		// todo: set time
		
		if ([[tc identifier] isEqualToString:@"x"])
			[pos setValue:objectValue forKey:@"x"];
		else if ([[tc identifier] isEqualToString:@"y"])
			[pos setValue:objectValue forKey:@"y"];
		else if ([[tc identifier] isEqualToString:@"z"])
			[pos setValue:objectValue forKey:@"z"];
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		switch([[editableTrajectory valueForKey:@"trajectoryType"] intValue])
		{
			case breakpointType:
				return [self breakpointTrajectory:editableTrajectory setValue:(id)objectValue forTableColumn:tc row:row];
				break;
			case rotationType:
				return [self rotationTrajectory:editableTrajectory setValue:(id)objectValue forTableColumn:tc row:row];
				break;
			case randomType:
				return [self randomTrajectory:editableTrajectory setValue:(id)objectValue forTableColumn:tc row:row];
				break;
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
}

#pragma mark -
#pragma mark NSTableView - getting values - specialised
// -----------------------------------------------------------

//- (id)breakpointTrajectory:(id)trajectory valueForTableColumn:(id)tc row:(int)row
//{
//	if(row == 0)
//	{
//		if ([[tc identifier] isEqualToString:@"name"]) return @"Region";
//		else if ([[tc identifier] isEqualToString:@"time"]) return @"Time";
//		else return [tc identifier];
//	}
//	else
//	{
//		row--;
//		
//		id breakpoint = [[trajectory linkedBreakpointArrayWithInitialPosition:nil] objectAtIndex:row];
//		if ([[tc identifier] isEqualToString:@"time"])
//		{
//			return [NSNumber numberWithUnsignedLong:[[breakpoint valueForKey:@"time"] unsignedLongValue]];
//		}
//		else
//		{
//			if([[trajectory valueForKey:@"adaptiveInitialPosition"] boolValue] && row == 0)
//				return @">";
//			else
//				return [NSString stringWithFormat:@"%0.3f", [[breakpoint valueForKey:[tc identifier]] doubleValue]];
//		}
//
//	}
//}


#pragma mark -
#pragma mark NSTableView - setting values - specialised
// -----------------------------------------------------------


- (void)breakpointTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row
{
	TrajectoryItem *editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];

	if(row > 0) // row = 0 is header
	{
		row--;
		if (row > 0 && // time is unchangeable for first brekpoint
			[[tc identifier] isEqualToString:@"time"])
		{
			[[[editableTrajectory linkedBreakpointArrayWithInitialPosition:nil] objectAtIndex:row] setTime:[objectValue intValue]];
			[editableTrajectory sortBreakpoints];
		}
		else
		{
			[[[editableTrajectory linkedBreakpointArrayWithInitialPosition:nil] objectAtIndex:row] setValue:objectValue forKey:[tc identifier]];
		}	

		[editableTrajectory updateModel];	
	}
}

- (void)rotationTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row
{
}

- (void)randomTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row;
{
}



@end
