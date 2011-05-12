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
	
	BOOL isVertical;

	NSColor *tickColor;
	NSColor *overloadColor;
	NSColor *hotColor;
	NSColor *coolColor;	
}

- (void)drawVertical:(NSRect)dirtyRect;
- (void)drawHorizontal:(NSRect)dirtyRect;

- (void)setLevel:(float)dBValue;
- (void)setPeakLevel:(float)dBValue;

@end


@interface DBLabelsView : NSView

@end