//
//  BreakpointArray.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Breakpoint.h"

@interface BreakpointArray : NSObject
{
    NSMutableArray *breakpoints;
}

@property (retain) NSMutableArray *breakpoints;

// deriving new arrays
- (BreakpointArray *)filteredBreakpointArrayUsingDescriptor:(NSString *)descriptor;

// actions
- (void)addBreakpoint:(Breakpoint *)bp;
- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
- (void)removeBreakpoint:(id)bp;
- (void)removeBreakpointsWithDescriptor:(NSString *)descriptor;
- (void)sort;

// accessors
- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;
- (id)lastObject;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len;

- (void)cropStart:(float)start duration:(float)duration;

// interpolated values
- (SpatialPosition *)interpolatedPositionAtTime:(NSUInteger)time;
- (float)interpolatedValueAtTime:(NSUInteger)time;


@end
