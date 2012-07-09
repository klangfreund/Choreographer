//
//  TableEditorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 25.10.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
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

- (void)refreshView
{
//	NSLog(@"Table Editor refresh view");
	
	displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	[tableEditorView reloadData];
	
	// hide name column for trajectories
//	NSTableColumn *column = [tableEditorView tableColumnWithIdentifier:@"name"];
//	
//	if(displayMode == regionDisplayMode)
//	{
//		[column setHidden:NO];
//		[column setEditable:NO];
//	}
//	else
//	{
//		[column setHidden:YES];
//		[column setEditable:NO];
//	}

	// selection
 
	if(displayMode != locatorDisplayMode)
    {
        NSMutableIndexSet *rowIndexes = [[[NSMutableIndexSet alloc] init] autorelease];

        for(id item in [[EditorContent sharedEditorContent] valueForKey:@"editorSelection"])
        {
            if(displayMode == regionDisplayMode)
                [rowIndexes addIndex:[[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] indexOfObject:item] + 1];
            else if(displayMode == trajectoryDisplayMode)
            {
                TrajectoryItem *editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
                NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
                [tempArray addObjectsFromArray:editableTrajectory.positionBreakpoints];
                [tempArray addObjectsFromArray:[editableTrajectory parameterBreakpoints]];
                NSInteger index = [tempArray indexOfObject:item];
                if(index != NSNotFound)
                    [rowIndexes addIndex:index + 1];
            }
        }		
        [tableEditorView selectRowIndexes:rowIndexes byExtendingSelection:NO];
    }
}

#pragma mark -
#pragma mark menu actions
// -----------------------------------------------------------


- (IBAction)addBreakpoint:(id)sender
{
    SpatialPosition *newPos = [SpatialPosition positionWithX:0 Y:0 Z:0];
    [[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] addBreakpointAtPosition:newPos time:-1];
}

- (BOOL)validateUserInterfaceItem:(id)item
{    
	if ([item action] == @selector(addBreakpoint:) && displayMode == trajectoryDisplayMode)
    {
        return YES;
    }
    
    return NO;
}



#pragma mark -
#pragma mark NSTableView - delegate methods
// -----------------------------------------------------------

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id selectedIndices = [tableEditorView selectedRowIndexes];
	id editorSelection = [[EditorContent sharedEditorContent] valueForKey:@"editorSelection"];
	id editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];

	[editorSelection removeAllObjects];

	NSInteger i = [selectedIndices firstIndex];
	
//	if(i == 0) return;
//	   !editableTrajectory ||
//	   displayMode == trajectoryDisplayMode && [[editableTrajectory valueForKey:@"trajectoryType"] intValue] != breakpointType)
//		return;
		
    if(displayMode == regionDisplayMode)
    {
        while(i != NSNotFound)
        {
            [editorSelection addObject:[[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] objectAtIndex:i - 1]];
            i = [selectedIndices indexGreaterThanIndex:i];
        }
    }
    else if(displayMode == trajectoryDisplayMode)
    {
        NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
        [tempArray addObjectsFromArray:[editableTrajectory positionBreakpoints]];
        [tempArray addObjectsFromArray:[editableTrajectory parameterBreakpoints]];

        while(i != NSNotFound)
        {
			[editorSelection addObject:[tempArray objectAtIndex:i - 1]];
            i = [selectedIndices indexGreaterThanIndex:i];
		}		
	}

	// update views
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
}


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tc row:(NSInteger)row;
{
	// draw background for title rows
	
	if(displayMode == regionDisplayMode || displayMode == locatorDisplayMode)
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
				return (row != 0);
				break;
			case randomType:
				return (row != 0);
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
	int n, sum;

	if(displayMode == regionDisplayMode || displayMode == locatorDisplayMode)
	{
		// plus 1: title row
		return [[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] count] + 1;
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		sum = 0;
		
		// linked breakpoints (if any) plus title row
		n = [[[EditorContent sharedEditorContent] valueForKeyPath:@"editableTrajectory.positionBreakpoints"] count];
		if(n) sum += n + 1;
			
		// additional positions (if any) plus title row
		n = [[[EditorContent sharedEditorContent] valueForKeyPath:@"editableTrajectory.parameterBreakpoints"] count];
		if(n) sum += n + 1;

		return sum;
	}
	else return 0;
}


// Table view: getting values
// -----------------------------------------------------------

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(id)tc row:(NSInteger)row
{
//	NSLog(@"%@ objectValueForTableColumn", [self className]);

	NSArray *displayedRegions = [[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"];
	id editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	SpatialPosition *pos;
	int n, sum;
	
	if(displayMode == regionDisplayMode || displayMode == locatorDisplayMode)
	{
		if(row == 0)
		{
			if ([[tc identifier] isEqualToString:@"type"]) return @"Region";
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

			if ([[tc identifier] isEqualToString:@"type"])
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
		n = [[editableTrajectory positionBreakpointsWithInitialPosition:nil] count];
		if(n)
		{
			if(row == sum)
			{
                if ([[tc identifier] isEqualToString:@"type"]) return @"Breakpoints";
				else if ([[tc identifier] isEqualToString:@"time"]) return @"Time";
				else return [tc identifier];
			}
			else if(row <= sum + n)
			{
				row -= sum + 1;
				
				Breakpoint* breakpoint = [[editableTrajectory positionBreakpointsWithInitialPosition:nil] objectAtIndex:row];
				if ([[tc identifier] isEqualToString:@"type"])
                {
                    return @"";
                }
                else if ([[tc identifier] isEqualToString:@"time"])
				{
					return [NSString stringWithFormat:@"%d", [breakpoint time]];
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
		n = [[editableTrajectory parameterBreakpoints] count];
		if(n)
		{			
			if(row == sum)
			{
				return [tc identifier];
			}
			else if(row <= n + sum)
			{
				row -= sum + 1;
				
				Breakpoint* breakpoint = [[editableTrajectory parameterBreakpoints] objectAtIndex:row];
				if ([[tc identifier] isEqualToString:@"type"])
				{
					return [breakpoint descriptor];
				}
				else if ([[tc identifier] isEqualToString:@"time"])
				{
					if([breakpoint hasTime])
                       return [NSString stringWithFormat:@"%d", [breakpoint time]];
                    else
                       return @"-";
				}
				else
				{
                    if([[breakpoint descriptor] isEqualToString:@"Init"] &&
                       [[editableTrajectory valueForKey:@"adaptiveInitialPosition"] boolValue])
                        return @">";
                    else if([breakpoint breakpointType] != breakpointTypeValue)
                        return [NSString stringWithFormat:@"%0.3f", [[[breakpoint position] valueForKey:[tc identifier]] doubleValue]];
                    else if([[tc identifier] isEqualToString:@"x"])
                        return [NSString stringWithFormat:@"%0.3f", [breakpoint value]];
                    else
                        return @"";
				}
			}

			sum += n + 1;
		}		
	}
	return nil;
}

// Table view: setting values
// -----------------------------------------------------------

- (void)tableView:(NSTableView *)tv setObjectValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(NSInteger)row
{
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

        [[EditorContent sharedEditorContent] updateModelForSelectedPoints];
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
#pragma mark NSTableView - setting values - specialised
// -----------------------------------------------------------


- (void)breakpointTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row
{
	TrajectoryItem *editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];

	if(row > 0) // row = 0 is header
	{
		row--;
		if ([[tc identifier] isEqualToString:@"time"])
		{
			if([objectValue integerValue] < 1 ||	// time cannot be negative
				row == 0)							// time is unchangeable for first brekpoint
				return;
			[[[editableTrajectory positionBreakpointsWithInitialPosition:nil] objectAtIndex:row] setTime:[objectValue integerValue]];
			[editableTrajectory sortBreakpoints];
		}
		else
		{
			[[[editableTrajectory positionBreakpointsWithInitialPosition:nil] objectAtIndex:row] setValue:objectValue forKey:[tc identifier]];
		}	

		[editableTrajectory updateModel];	
	}
}

- (void)rotationTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row
{
	TrajectoryItem *editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	
    NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
    [tempArray addObjectsFromArray:[editableTrajectory positionBreakpoints]];
    [tempArray addObjectsFromArray:[editableTrajectory parameterBreakpoints]];
    
    Breakpoint* bp = [tempArray objectAtIndex:row - 1];

    if ([[tc identifier] isEqualToString:@"time"])
        [bp setTime:[objectValue integerValue]];
    else if([bp breakpointType] != breakpointTypeValue)
        [bp setValue:objectValue forKey:[tc identifier]];
    else if([[tc identifier] isEqualToString:@"x"])
        [bp setValue:objectValue forKey:@"value"];

    [editableTrajectory sortBreakpoints];
	[editableTrajectory updateModel];	
}

- (void)randomTrajectory:(id)trajectory setValue:(id)objectValue forTableColumn:(NSTableColumn *)tc row:(int)row;
{
	TrajectoryItem *editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	
    NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
    [tempArray addObjectsFromArray:[editableTrajectory positionBreakpoints]];
    [tempArray addObjectsFromArray:[editableTrajectory parameterBreakpoints]];
    
    Breakpoint* bp = [tempArray objectAtIndex:row - 1];
    
    if ([[tc identifier] isEqualToString:@"time"])
        [bp setTime:[objectValue integerValue]];
    else if([bp breakpointType] != breakpointTypeValue)
        [bp setValue:objectValue forKey:[tc identifier]];
    else if([[tc identifier] isEqualToString:@"x"])
        [bp setValue:objectValue forKey:@"value"];
    
    [editableTrajectory sortBreakpoints];
	[editableTrajectory updateModel];	
}



@end
