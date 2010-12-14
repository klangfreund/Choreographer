//
//  AudioRegion.h
//  Choreographer
//
//  Created by Philippe Kocher on 15.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Region.h"
#import "SpatialPosition.h"


@interface AudioRegion : Region
{
	SpatialPosition *position;	

	Breakpoint *tempBp1, *tempBp2;
}	
// drawing
- (void)drawRect:(NSRect)rect;

// position
- (SpatialPosition *)regionPosition;
- (SpatialPosition *)regionPositionAtTime:(NSUInteger)time;
- (SpatialPosition *)interpolatedPosition:(NSUInteger)time
							  breakpoint1:(Breakpoint *)bp1
							  breakpoint2:(Breakpoint *)bp2;
//- (NSArray *)playbackBreakpointArray;

// update model
- (void)updatePositionInModel;
- (void)undoableSetPositionX:(float)newX y:(float)newY z:(float)newZ;

@end
