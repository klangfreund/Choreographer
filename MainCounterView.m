//
//  MainCounterView.m
//  Choreographer
//
//  Created by Philippe Kocher on 25.03.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "MainCounterView.h"


@implementation MainCounterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		fontSize = 20;
	}
    return self;
}

- (void)setType:(int)value
{
	type = value;
	
	switch(type)
	{
		case H_M_S_CounterType:
			numberField[0] = NSMakeRect(10, 12, 16, 25);
			numberFieldFormatter[0] = formatter1;
			numberFieldModulo[0] = 10;
			numberField[1] = NSMakeRect(36, 12, 28, 25);
			numberFieldFormatter[1] = formatter2;
			numberFieldModulo[1] = 100;
			numberField[2] = NSMakeRect(74, 12, 28, 25);
			numberFieldFormatter[2] = formatter2;
			numberFieldModulo[2] = 100;
			numberField[3] = NSMakeRect(112, 12, 40, 25);
			numberFieldFormatter[3] = formatter3;
			numberFieldModulo[3] = 1000;

			countNumberFields = 4;

			separator[0] = nil;
			separatorPoint[0] = NSMakePoint(0, 0);
			separator[1] = @":";
			separatorPoint[1] = NSMakePoint(26, 12);
			separator[2] = @":";
			separatorPoint[2] = NSMakePoint(64, 12);
			separator[3] = @".";
			separatorPoint[3] = NSMakePoint(102, 12);

			break;
			
		default:
			countNumberFields = 0;
	}
}

- (void)setLocator:(NSUInteger)value
{	
	locators[0] = value;
	selectedNumberField = -1; // no selection when audio is running
	
	[self locatorAtIndex:0 toNumberFieldsStartingAtIndex:0];
	
	[self setNeedsDisplay:YES];
}

- (void)commitValues
{
	[self numberFieldsStartingAtIndex:0 toLocatorAtIndex:0];
	[playbackController setLocator:locators[0]];
}


@end
