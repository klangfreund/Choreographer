//
//  CounterView.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.08.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "CounterView.h"
#import "CHProjectDocument.h"
#import "PlaybackController.h"


@implementation CounterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		selectedNumberField = -1;
		countNumberFields = 0;

		formatter1 = [[NSNumberFormatter alloc] init];
		[formatter1 setFormat:@"0"];
		
		formatter2 = [[NSNumberFormatter alloc] init];
		[formatter2 setFormat:@"00"];
		
		formatter3 = [[NSNumberFormatter alloc] init];
		[formatter3 setFormat:@"000"];
		
		[self setType:H_M_S_CounterType];
	}
    return self;
}

- (void)dealloc
{
	NSLog(@"CounterView: dealloc");
	[formatter1 release];
	[formatter2 release];
	[formatter3 release];
	[super dealloc];
}

#pragma mark -
#pragma mark drawing

- (void)drawRect:(NSRect)rect
{
	// background
	int i;
	NSRect bgr = [self bounds];

	int height = bgr.size.height;
	bgr.size.height = 1;

	for(i=rect.origin.y;i<rect.origin.y + rect.size.height;i++)
	{
		if(i < 25)
			[[NSColor colorWithCalibratedRed: 1 - i * 0.01 green: 1 - i * 0.005 blue: 1 alpha: 1.0] set];
		else
			[[NSColor colorWithCalibratedRed: 0.385 + i * 0.01 green: 0.691 + i * 0.005 blue: 1 alpha: 1.0] set];
			
		bgr.origin.y = height - i;
		NSRectFill(bgr);
	}

	// frame
	bgr = [self bounds];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bgr];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,bgr.size.height) toPoint:NSMakePoint(bgr.size.width,bgr.size.height)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,0) toPoint:NSMakePoint(0,bgr.size.height)];
	[[NSColor grayColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,bgr.size.height-1) toPoint:NSMakePoint(bgr.size.width,bgr.size.height-1)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(1,0) toPoint:NSMakePoint(1,bgr.size.height)];

	// number fields
	NSString *field;
	NSMutableDictionary *attrs;
	NSMutableDictionary *attrsDeselected = [NSMutableDictionary dictionary];
	NSMutableDictionary *attrsSelected = [NSMutableDictionary dictionary];
	NSMutableDictionary *attrsFirstSeparator = [NSMutableDictionary dictionary];
	[attrsDeselected setObject:[NSFont systemFontOfSize:fontSize] forKey:NSFontAttributeName];
	[attrsSelected setObject:[NSFont systemFontOfSize:fontSize] forKey:NSFontAttributeName];
	[attrsSelected setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[attrsFirstSeparator setObject:[NSFont systemFontOfSize:fontSize] forKey:NSFontAttributeName];
	[attrsFirstSeparator setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	
	
	if(selectedNumberField != -1)
	{
		// highlight selected field
		[[NSColor colorWithCalibratedRed:0.3 green:0.4 blue:0.5 alpha:0.9] set];
		NSRectFill(numberField[selectedNumberField]);
	}

	for(i=0;i<countNumberFields;i++)
	{
		field = [numberFieldFormatter[i] stringFromNumber:[NSNumber numberWithInt: numberFieldValue[i]]];
		attrs = selectedNumberField == i ? attrsSelected : attrsDeselected;
		[field drawAtPoint:numberField[i].origin withAttributes:attrs];
	}	
	
	for(i=0;i<countNumberFields;i++)
	{
		field = separator[i];
		attrs = i%4 == 0 ? attrsFirstSeparator : attrsDeselected;
		[field drawAtPoint:separatorPoint[i] withAttributes:attrs];
	}	
}


#pragma mark -
#pragma mark mouse & keyboard

- (BOOL)acceptsFirstResponder
{ 
	id document = [[[self window] windowController] document];
	return ![[document valueForKey:@"playbackController"] isPlaying];
}

- (BOOL)becomeFirstResponder { /*NSLog(@"counter view -- becomeFirstResponder...");*/ return YES; }
- (BOOL)resignesFirstResponder { selectedNumberField = -1; [self setNeedsDisplay:YES]; return YES; }

- (void)mouseDown:(NSEvent *)event
{
	NSPoint local_point = [self convertPoint:[event locationInWindow] fromView:nil];
	int i;
	selectedNumberField = -1;
	
	for(i=0;i<countNumberFields;i++)
	{
		if(NSPointInRect(local_point, numberField[i]))
		{
			selectedNumberField = i;
			selectedNumberFieldFirstInput = i;
			break;
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)event
{
	// todo: mouse up/down to increment/decrement value
}

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	int i = [event modifierFlags] & NSShiftKeyMask ? -1 : 1; 
	NSLog(@"Counter View key code: %d ", keyCode);

	int num = -1;
	
	switch(keyCode)
	{
		// numbers
		case 18:
		case 83:
			num = 1; break;
		case 19:
		case 84:
			num = 2; break;
		case 20:
		case 85:
			num = 3; break;
		case 21:
		case 86:
			num = 4; break;
		case 22:
		case 87:
			num = 5; break;
		case 25:
		case 88:
			num = 6; break;
		case 26:
		case 89:
			num = 7; break;
		case 28:
		case 91:
			num = 8; break;
		case 23:
		case 92:
			num = 9; break;
		case 29:
		case 82:
			num = 0; break;

		// tab or dot
		case 48:
		case 47:
		case 65:
			[self rotateSelectionBy:i];
			return;
			
		//carriage return
		case 36:
		// enter
		case 76:
			[self commitValues];
			[[self window] makeFirstResponder:nil];
			return;
			
			
		// spacebar = PLAY / PAUSE
		case 49:
			[self commitValues];
			[[self window] makeFirstResponder:nil];
			
			id document = [[[self window] windowController] document];
			[document startStop];
			
			return;
	}
	
	if(num == -1)
		[self setNumber:0 reset:YES];
	else
		[self setNumber:num reset:NO];

}



#pragma mark -
#pragma mark setter

- (void)setNumber:(int)num reset:(BOOL)reset
{
	int oldValue = numberFieldValue[selectedNumberField];
	
	if(reset)
	{
		oldValue = num = 0;
	}
	if(selectedNumberFieldFirstInput == selectedNumberField)
	{
		oldValue = 0;
		selectedNumberFieldFirstInput = -1;
	}
	
	num = (num + 10 * oldValue) % numberFieldModulo[selectedNumberField];
	numberFieldValue[selectedNumberField] = num;

	[self setNeedsDisplay:YES];
}

- (void)rotateSelectionBy:(int)i
{
	selectedNumberField += i;
	selectedNumberField = selectedNumberField >= countNumberFields ? 0 : selectedNumberField;
	selectedNumberField = selectedNumberField < 0 ? countNumberFields - 1 : selectedNumberField;

	selectedNumberFieldFirstInput = selectedNumberField;

	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark mathematics

- (void)locatorAtIndex:(int)locIndex toNumberFieldsStartingAtIndex:(int)fieldIndex
{		
	NSUInteger miliseconds = locators[locIndex];
	
	numberFieldValue[fieldIndex + 3] = miliseconds % 1000;
	numberFieldValue[fieldIndex + 2] = (miliseconds / 1000) % 60;
	numberFieldValue[fieldIndex + 1] = (miliseconds / 60000) % 60;
	numberFieldValue[fieldIndex]	 = (miliseconds / 3600000);
}

- (void)numberFieldsStartingAtIndex:(int)fieldIndex toLocatorAtIndex:(int)locIndex
{
	NSUInteger miliseconds;
	
	miliseconds = 
	numberFieldValue[fieldIndex + 3] +
	numberFieldValue[fieldIndex + 2] * 1000 +
	numberFieldValue[fieldIndex + 1] * 60000 +
	numberFieldValue[fieldIndex]	 * 3600000;
	
	locators[locIndex] = miliseconds;
}

#pragma mark -
#pragma mark abstract methods

- (void)setType:(int)value {}
- (void)setLocator:(NSUInteger)value {}
- (void)setLocators {}
- (void)commitValues {}

@end