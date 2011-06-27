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
	float level;
	float peakLevel;
	int	  peakLevelCounter;
	
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

@interface LevelMeterPeakView : NSView
{
	IBOutlet id owner;
	float level;

	NSColor *normalColor;
	NSColor *overloadColor;
}

- (void)setLevel:(float)dBValue;

@end

@interface DBLabelsView : NSView
@end