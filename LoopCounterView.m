//
//  LoopCounterView.m
//  Choreographer
//
//  Created by Philippe Kocher on 25.03.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "LoopCounterView.h"


@implementation LoopCounterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		fontSize = 14;

		// register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(update:)
													 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
		
	}
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)setType:(int)value
{
	type = value;
	
	switch(type)
	{
		case H_M_S_CounterType:

			// start
			numberField[0] = NSMakeRect(50, 24, 10, 18);
			numberFieldFormatter[0] = formatter1;
			numberFieldModulo[0] = 10;

			numberField[1] = NSMakeRect(65, 24, 18, 18);
			numberFieldFormatter[1] = formatter2;
			numberFieldModulo[1] = 100;

			numberField[2] = NSMakeRect(88, 24, 18, 18);
			numberFieldFormatter[2] = formatter2;
			numberFieldModulo[2] = 100;

			numberField[3] = NSMakeRect(111, 24, 27, 18);
			numberFieldFormatter[3] = formatter3;
			numberFieldModulo[3] = 1000;

			// end
			numberField[4] = NSMakeRect(190, 24, 10, 18);
			numberFieldFormatter[4] = formatter1;
			numberFieldModulo[4] = 10;

			numberField[5] = NSMakeRect(205, 24, 18, 18);
			numberFieldFormatter[5] = formatter2;
			numberFieldModulo[5] = 100;

			numberField[6] = NSMakeRect(228, 24, 18, 18);
			numberFieldFormatter[6] = formatter2;
			numberFieldModulo[6] = 100;

			numberField[7] = NSMakeRect(251, 24, 27, 18);
			numberFieldFormatter[7] = formatter3;
			numberFieldModulo[7] = 1000;

			// dur
			numberField[8] = NSMakeRect(190, 6, 10, 18);
			numberFieldFormatter[8] = formatter1;
			numberFieldModulo[8] = 10;

			numberField[9] = NSMakeRect(205, 6, 18, 18);
			numberFieldFormatter[9] = formatter2;
			numberFieldModulo[9] = 100;

			numberField[10] = NSMakeRect(228, 6, 18, 18);
			numberFieldFormatter[10] = formatter2;
			numberFieldModulo[10] = 100;

			numberField[11] = NSMakeRect(251, 6, 27, 18);
			numberFieldFormatter[11] = formatter3;
			numberFieldModulo[11] = 1000;

			countNumberFields = 12;

			separator[0] = @"start";
			separatorPoint[0] = NSMakePoint(10, 24);
			separator[1] = @":";
			separatorPoint[1] = NSMakePoint(60, 24);
			separator[2] = @":";
			separatorPoint[2] = NSMakePoint(83, 24);
			separator[3] = @".";
			separatorPoint[3] = NSMakePoint(106, 24);
			
			separator[4] = @"end";
			separatorPoint[4] = NSMakePoint(158, 24);
			separator[5] = @":";
			separatorPoint[5] = NSMakePoint(200, 24);
			separator[6] = @":";
			separatorPoint[6] = NSMakePoint(223, 24);
			separator[7] = @".";
			separatorPoint[7] = NSMakePoint(246, 24);
			
			separator[8] = @"dur";
			separatorPoint[8] = NSMakePoint(158, 6);
			separator[9] = @":";
			separatorPoint[9] = NSMakePoint(200, 6);
			separator[10] = @":";
			separatorPoint[10] = NSMakePoint(223, 6);
			separator[11] = @".";
			separatorPoint[11] = NSMakePoint(246, 6);
			
			break;
			
		default:
			countNumberFields = 0;
	}
}

- (void)update:(NSNotification *)notification
{
	if([[notification userInfo] objectForKey:NSUpdatedObjectsKey])
	{
		// todo: only when loop region changes
		[self setLocators];
	}
}

- (void)setLocators
{	
	id document = [[[self window] windowController] document];	

	locators[0] = [[document valueForKeyPath:@"projectSettings.loopRegionStart"] unsignedLongValue];
	locators[1] = [[document valueForKeyPath:@"projectSettings.loopRegionEnd"] unsignedLongValue];
	locators[2] = locators[1] - locators[0];
	selectedNumberField = -1; // no selection when audio is running
	
	[self locatorAtIndex:0 toNumberFieldsStartingAtIndex:0];
	[self locatorAtIndex:1 toNumberFieldsStartingAtIndex:4];
	[self locatorAtIndex:2 toNumberFieldsStartingAtIndex:8];
	
	[self setNeedsDisplay:YES];
}

- (void)commitValues
{
	NSUInteger tempEndLocator = locators[1];
	
	[self numberFieldsStartingAtIndex:0 toLocatorAtIndex:0];
	[self numberFieldsStartingAtIndex:4 toLocatorAtIndex:1];
	[self numberFieldsStartingAtIndex:8 toLocatorAtIndex:2];
	
	if(locators[1] < locators[0])
		locators[1] = locators[0];

	id document = [[[self window] windowController] document];

	[document setValue:[NSNumber numberWithUnsignedLong:locators[0]] forKeyPath:@"projectSettings.loopRegionStart"];
	
	if(tempEndLocator != locators[1]) // loop region end has been changed
	{
		[document setValue:[NSNumber numberWithUnsignedLong:locators[1]] forKeyPath:@"projectSettings.loopRegionEnd"];
	}
	else
	{
		[document setValue:[NSNumber numberWithUnsignedLong:locators[0] + locators[2]] forKeyPath:@"projectSettings.loopRegionEnd"];
	}
}

@end
