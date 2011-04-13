//
//  RulerView.h
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//



#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"


#define NUM_OF_LABELS 50
#define HEIGHT_1 12	// playhead area
#define HEIGHT_2 12 // marker area

@interface RulerView : NSView
{
	IBOutlet id playbackController;

	int type;
	NSTextField *labels[NUM_OF_LABELS];
	
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

