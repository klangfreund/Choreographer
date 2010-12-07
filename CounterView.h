//
//  CounterView.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.08.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CounterTextBox : NSTextField
{
	NSColor *textColor;
}
@end

@interface CounterSmallNumberBox : CounterTextBox
@end

@interface CounterLargeNumberBox : CounterTextBox
- (void)select;
- (void)deselect;
@end


@interface CounterView : NSView
{
	IBOutlet id document;
	IBOutlet id playbackController;
	
	NSArray *counterNumberBoxes;
	NSArray *startNumberBoxes;
	NSArray *endNumberBoxes;
	NSArray *lengthNumberBoxes;

	NSNumberFormatter *formatter1, *formatter2;
	CounterLargeNumberBox *selectedNumberBox;
}

- (void)setLocator:(unsigned long)value;
- (void)setSelectionFrom:(unsigned long)startTime to:(unsigned long)endTime;

- (void)setSelectedNumberBox:(CounterLargeNumberBox *)box;
- (void)rotateSelection;
- (BOOL)hasSelectedNumberBox;

- (void)setNumber:(int)num;

@end

void miliseconds_to_time(unsigned long miliseconds, int *time);
