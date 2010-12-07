//
//  SpatialPosition.h
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SpatialPosition : NSObject
{
	float x,y,z;
	float a,e,d;
}

+ (SpatialPosition *)position;
+ (SpatialPosition *)positionWithX:(float)x Y:(float)y Z:(float)z;

// accessors
- (SpatialPosition *)position;

- (void) setX:(float)value;
- (void) setY:(float)value;
- (void) setZ:(float)value;
- (void) setA:(float)value;
- (void) setE:(float)value;
- (void) setD:(float)value;

- (float) x;
- (float) y;
- (float) z;
- (float) a;
- (float) e;
- (float) d;


// mathematics
- (void)cartopol;
- (void)poltocar;

@end
