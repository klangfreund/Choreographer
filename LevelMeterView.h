//
//  LevelMeterView.h
//  Choreographer
//
//  Created by Philippe Kocher on 28.04.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LevelMeterView : NSView
{
	IBOutlet id owner;
	float level;
	float peakLevel;
}

- (void)setLevel:(float)dBValue;
- (void)setPeakLevel:(float)dBValue;

@end
