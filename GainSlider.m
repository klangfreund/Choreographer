//
//  GainSlider.m
//  Choreographer
//
//  Created by Philippe Kocher on 15.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "GainSlider.h"


@implementation GainSlider


- (void)mouseDown:(NSEvent *)event
{
	if([event clickCount] > 1)
	{
        // on double click reset value to 0
        [super setIntValue:0];
		return;
	}

    [super mouseDown:event];
}

@end
