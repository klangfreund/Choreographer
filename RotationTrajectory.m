//
//  RotationTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 16.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "RotationTrajectory.h"


@implementation RotationTrajectory

- (id)initWithTrajectoryItem:(TrajectoryItem *)item;
{
    self = [super init];
	if(self)
	{
        trajectoryItem = item;
        parameterBreakpointArray = [[BreakpointArray alloc] init];
        Breakpoint *bp;

		initialPosition = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.5 Y:0 Z:0]] retain];
        [initialPosition setDescriptor:@"Init"];
        [parameterBreakpointArray addBreakpoint:initialPosition];

		rotationCentre = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.0 Y:0 Z:0]] retain];
        [rotationCentre setDescriptor:@"Center"];
        [parameterBreakpointArray addBreakpoint:rotationCentre];
                
        if([[trajectoryItem valueForKey:@"trajectoryType"] intValue] == rotationAngleType)
        {
            bp = [Breakpoint breakpointWithTime:0 value:0];
            [bp setDescriptor:@"Angle"];
            [bp setTimeEditable:NO]; // initial angle, time not editable
            [bp setBreakpointType:breakpointTypeInitial];
            [parameterBreakpointArray addBreakpoint:bp];
            
//            bp = [Breakpoint breakpointWithTime:[[trajectoryItem valueForKey:@"duration"] unsignedLongValue] value:360];
//            [bp setDescriptor:@"Angle"];
//            [parameterBreakpointArray addBreakpoint:bp];
        }
        if([[trajectoryItem valueForKey:@"trajectoryType"] intValue] == rotationSpeedType)
        {
            bp = [Breakpoint breakpointWithTime:0 value:10];
            [bp setDescriptor:@"Speed"];
            [bp setTimeEditable:NO]; // initial speed, time not editable
            [bp setBreakpointType:breakpointTypeInitial];
            [parameterBreakpointArray addBreakpoint:bp];
        }    
    }

    return self;	
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    parameterBreakpointArray = [[coder decodeObjectForKey:@"parameterBreakpointArray"] retain];

    for(Breakpoint *bp in parameterBreakpointArray)
    {
        if([[bp descriptor] isEqualToString:@"Center"])
            rotationCentre = [bp retain];
        else if([[bp descriptor] isEqualToString:@"Init"])
            initialPosition = [bp retain];
    }
    
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:parameterBreakpointArray forKey:@"parameterBreakpointArray"];
}

- (void)dealloc
{
    [rotationCentre release];
    [initialPosition release];
    [parameterBreakpointArray release];
	[super dealloc];
}


- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger originalDur = [[trajectoryItem valueForKey:@"duration"] unsignedLongValue];
	NSUInteger duration;
	NSUInteger time = 0;
    int direction = 1;
	
	Breakpoint *bp;
	SpatialPosition *startPosition, *tempPosition;
    
    BreakpointArray *speedBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Speed"];
    BreakpointArray *angleBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Angle"];
    float speed;
    int timeIncrement;
	int azimuthIncrement;
    BOOL translation = NO;

	if(pos)
		startPosition = [[pos copy] autorelease];
	else
		startPosition = [[[initialPosition position] copy] autorelease];
    
    // translate
    if(rotationCentre.x != 0.0 ||
       rotationCentre.y != 0.0)
    {
        startPosition.x -= rotationCentre.x;
        startPosition.y -= rotationCentre.y;
        translation = YES;
    }
    
    tempPosition = [[startPosition copy] autorelease];
	
	NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];

	if(mode == durationModeOriginal)
	{
		duration = originalDur;
		duration = duration > dur ? dur : duration;
	}
	else
		duration = dur;
	
    while(time <= duration)
    {
        bp = [[[Breakpoint alloc] init] autorelease];
        [bp setPosition:[[tempPosition copy] autorelease]];
        [bp setTime:time];
        
        if(translation)  // translate back
        {
            bp.position.x += rotationCentre.x;
            bp.position.y += rotationCentre.y;
        }        
        
        [tempArray addObject:bp];
        
        if([[trajectoryItem valueForKey:@"trajectoryType"] intValue] == rotationAngleType)
        {
            timeIncrement = 100;
            time += timeIncrement;
            
            if(mode == durationModeOriginal)
            {
                [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:time]];           
            }
            else if(mode == durationModeScaled)
            {
                double scalingFactor = (double)originalDur / dur;
                [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:time * scalingFactor]];
            }            
            else if(mode == durationModeLoop)
            {
                [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:(time % originalDur)]];                       
            }
            else if(mode == durationModePalindrome)
            {
                if(mode == durationModePalindrome && (time % originalDur) < timeIncrement && time > timeIncrement)
                    direction *= -1;
                
                if(direction == 1)
                    [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:(time % originalDur)]];                       
                else if(direction == -1)
                    [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:originalDur - (time % originalDur)]];                       
            }
        }
        else if([[trajectoryItem valueForKey:@"trajectoryType"] intValue] == rotationSpeedType)
        {
            if(mode == durationModeOriginal)
            {
                speed = [speedBreakpoints interpolatedValueAtTime:time];
            }
            else if(mode == durationModeScaled)
            {
                double scalingFactor = (double)originalDur / dur;
                speed = [speedBreakpoints interpolatedValueAtTime:time * scalingFactor];
            }            
            else if(mode == durationModeLoop)
            {
                speed = [speedBreakpoints interpolatedValueAtTime:(time % originalDur)];
            }
            else if(mode == durationModePalindrome)
            {
                if((time % originalDur) < timeIncrement && time > timeIncrement)
                    direction *= -1;

                if(direction == 1)
                    speed = [speedBreakpoints interpolatedValueAtTime:(time % originalDur)];
                else if(direction == -1)
                    speed = [speedBreakpoints interpolatedValueAtTime:originalDur - (time % originalDur)];
            }

            timeIncrement = 1000. / fabs(speed);
            time += timeIncrement;
            azimuthIncrement = speed > 0 ? 1 : -1;
            
            [tempPosition setA:[tempPosition a] + azimuthIncrement];
        }
    }

    // last bp
    if([[trajectoryItem valueForKey:@"trajectoryType"] intValue] == rotationAngleType &&
       (mode == durationModeOriginal || mode == durationModeScaled))
    {
        bp = [[[Breakpoint alloc] init] autorelease];
        [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:duration]];                       
        [bp setPosition:[[tempPosition copy] autorelease]];
        [bp setTime:duration];

        if(translation)  // translate back
        {
            bp.position.x += rotationCentre.x;
            bp.position.y += rotationCentre.y;
        }        

        [tempArray addObject:bp];
    }

    return [NSArray arrayWithArray:tempArray];
}

@end
