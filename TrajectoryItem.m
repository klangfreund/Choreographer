//
//  TrajectoryItem.m
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "TrajectoryItem.h"
#import "Trajectory.h"


@implementation TrajectoryItem

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (void)awakeFromInsert
{
	[super awakeFromInsert];
//	NSLog(@"TrajectoryItem %@ awakeFromInsert", self);
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
//	NSLog(@"TrajectoryItem %@ awakeFromFetch", self);

	[self unarchiveData];
}

- (void)dealloc
{
	[trajectory release];

	NSLog(@"TrajectoryItem %@ dealloc", self);
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
	trajectory = [[Trajectory trajectoryOfType:type forItem:self] retain];
	[trajectory setValue:self forKey:@"trajectoryItem"];
}

#pragma mark -
#pragma mark breakpoints for visualisation
// -----------------------------------------------------------

- (NSArray *)positionBreakpoints
{
	return [self positionBreakpointsWithInitialPosition:nil];
}
	
	
- (NSArray *)positionBreakpointsWithInitialPosition:(SpatialPosition *)pos
{
	if(![[self valueForKey:@"adaptiveInitialPosition"] boolValue])
		return [trajectory positionBreakpoints];
	
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
	
	NSMutableArray *tempArray = [[trajectory positionBreakpoints] copy];
	
	[tempArray replaceObjectAtIndex:0 withObject:bp];
	
	return tempArray;
}

- (NSArray *)parameterBreakpoints;
{
    return [trajectory parameterBreakpoints];
}


- (SpatialPosition *)namePosition
{
	SpatialPosition *pos1, *pos2;
	float x,y,z;
	
	if(![[self valueForKey:@"adaptiveInitialPosition"] boolValue])
	{
		switch([self trajectoryType])
		{
			case 0:
				return [(SpatialPosition *)[[trajectory valueForKeyPath:@"positionBreakpoints"] objectAtIndex:0] position];
			case 1:
				return [trajectory valueForKey:@"initialPosition"];
			case 2:
				return [trajectory valueForKey:@"initialPosition"];
			default:
				return [SpatialPosition positionWithX:0. Y:0. Z:0.];
		}
	}
	else
	{
		switch([self trajectoryType])
		{
			case 0:
				return [SpatialPosition positionWithX:0. Y:0. Z:0.];
			case 1:
				return [trajectory valueForKey:@"rotationCentre"];
			case 2:
				pos1 = [trajectory valueForKey:@"boundingVolumePoint1"];
				pos2 = [trajectory valueForKey:@"boundingVolumePoint2"];
				x = pos1.x + (pos2.x - pos1.x) * 0.5;
				y = pos1.y + (pos2.y - pos1.y) * 0.5;
				z = pos1.z + (pos2.z - pos1.z) * 0.5;
				return [SpatialPosition positionWithX:x Y:y Z:z];
			default:
				return [SpatialPosition positionWithX:0. Y:0. Z:0.];
		}
	}
	
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
#pragma mark etc
// -----------------------------------------------------------

- (void)updateModel
{
	// synchronize trajectory data
	// NSLog(@"Trajectory item %@: updateModel", self);
	
	// (re)calcalate duration
	if(trajectoryType == breakpointType)
	{
		[self setValue:[trajectory valueForKey:@"trajectoryDuration"] forKey:@"duration"];
	}
	    
	// store actual data in model
	[self archiveData];
	
	// undo
	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[managedObjectContext undoManager] setActionName:[NSString stringWithFormat:@"edit trajectory: %@", [self valueForKeyPath:@"node.name"]]];
	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self] undoableUpdate];
}

- (void)undoableUpdate
{
	[self unarchiveData];
	
	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self] undoableUpdate];	
}

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time
{
	[trajectory addBreakpointAtPosition:pos time:time];
    [self updateModel];
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