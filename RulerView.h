//
//  RulerView.h
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//



#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"


#define NUM_OF_LABELS 50
#define HEIGHT_1 12	// height of area 1 = bottom area (playhead)
#define HEIGHT_2 12 // heigth of area 2 = middle area (marker)

@interface RulerView : NSView
{
	IBOutlet id playbackController;

	int type;
	NSTextField *labels[NUM_OF_LABELS];

	int numOfAreas;
	
	float zoomFactor;
}

- (void)setHorizontalRulerType:(NSPopUpButton *)sender;

- (void)setZoomFactor:(NSNotification *)notification;
@end


typedef enum _HRulerType
{
	minSecRulerType = 0,
	samplesRulerType = 1
} HRulerType;

