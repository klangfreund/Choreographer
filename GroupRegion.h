//
//  GroupRegion.h
//  Choreographer
//
//  Created by Philippe Kocher on 26.08.09.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Region.h"


@interface GroupRegion : Region
{
	float height;
}

// child regions
- (void)addChildRegion:(Region *)aRegion;
- (void)removeAllChildRegions;

@end
