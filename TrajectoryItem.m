//
//  TrajectoryItem.m
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "TrajectoryItem.h"


@implementation TrajectoryItem

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	NSLog(@"TrajectoryItem %x awakeFromInsert", self);
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	NSLog(@"TrajectoryItem %x awakeFromFetch", self);

	[self unarchiveData];
}


- (void)dealloc
{
	[trajectory release];

	NSLog(@"TrajectoryItem %x dealloc", self);
	[super dealloc];
}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (TrajectoryType)trajectoryType
{
	return trajectoryType;
}

- (void)setTrajectoryType:(TrajectoryType)type
{
	trajectoryType = type;
	
	[trajectory release];
	trajectory = [[Trajectory trajectoryOfType:type] retain];
	[trajectory setValue:self forKey:@"trajectoryItem"];
}


#pragma mark -
#pragma mark breakpoints for visualisation
// -----------------------------------------------------------

- (NSArray *)linkedBreakpointArray
{
	return [self linkedBreakpointArrayWithInitialPosition:nil];
}
	
	
- (NSArray *)linkedBreakpointArrayWithInitialPosition:(SpatialPosition *)pos
{
	if(![[self valueForKey:@"adaptiveInitialPosition"] boolValue])
		return [trajectory linkedBreakpoints];
	
	// adaptive initial breakpoint
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	
	if(pos)
	{
		[bp setPosition:pos];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeInitial];
	}
	else
	{
		[bp setPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeAdaptiveInitial];
	}
	
	NSMutableArray *tempArray = [[trajectory linkedBreakpoints] mutableCopy];
	
	[tempArray replaceObjectAtIndex:0 withObject:bp];
	
	return tempArray;
}

- (NSArray *)additionalPositions
{
	return [trajectory additionalPositions];
}

- (NSString *)additionalPositionName:(id)item
{
	return [trajectory additionalPositionName:item];
}

#pragma mark -
#pragma mark breakpoints for audio playback
// -----------------------------------------------------------

- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	if([[self valueForKey:@"adaptiveInitialPosition"] boolValue])
		return [trajectory playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:dur mode:mode];
	else
		return [trajectory playbackBreakpointArrayWithInitialPosition:nil duration:dur mode:mode];
}

- (id)trajectoryAttributeForKey:(NSString *)key
{
	return [trajectory trajectoryAttributeForKey:key];
}


#pragma mark -
#pragma mark 
// -----------------------------------------------------------

- (void)updateModel
{
	// synchronize trajectory data
	// NSLog(@"Trajectory item: updateModel");
	
	// store actual data in model
	[self archiveData];
	
	// undo
	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[managedObjectContext undoManager] setActionName:[NSString stringWithFormat:@"edit trajectory: %@", [[self valueForKey:@"node"] valueForKey:@"name"]]];
	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self] undoableUpdate];
}

- (void)undoableUpdate
{
	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self] undoableUpdate];
	
	[self unarchiveData];
	
}

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time
{
	[trajectory addBreakpointAtPosition:pos time:time];
}



- (void)sortBreakpoints { [trajectory sortBreakpoints]; }
- (void)removeBreakpoint:(id)bp { [trajectory removeBreakpoint:bp]; }

- (NSString *)trajectoryTypeString
{
	switch([self trajectoryType])
	{
		case 0:
			return @"breakpoints";
		case 1:
			return @"rotation";
		case 2:
			return @"random";
		default:
			return @"-";
	}
}

- (NSString*)name;
{
	return [[self valueForKey:@"Node"] valueForKey:@"name"];
}

#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (void)archiveData
{ 
	NSMutableData *data;
	NSKeyedArchiver *archiver;
	
	data = [NSMutableData data];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:trajectory forKey:@"trajectory"];
	[archiver finishEncoding];
	
	[self setValue:data forKey:@"trajectoryData"];
	[archiver release];
}

- (void)unarchiveData
{
	NSMutableData *data;
	NSKeyedUnarchiver* unarchiver;
	
	[trajectory release];
	trajectory = nil;
	data = [self valueForKey:@"trajectoryData"];
	if(data)
	{
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		trajectory = [[unarchiver decodeObjectForKey:@"trajectory"] retain];
		[unarchiver finishDecoding];
		[unarchiver release];
		[trajectory setValue:self forKey:@"trajectoryItem"];
	}	
}	

@end