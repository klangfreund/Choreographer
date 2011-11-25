//
//  CounterView.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.08.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define countLocators 3
#define countFields 12

@interface CounterView : NSView
{
	int type;
	int fontSize;
	
	NSUInteger locators[countLocators];
	
	NSRect numberField[countFields];
	NSNumberFormatter *numberFieldFormatter[countFields];
	int numberFieldModulo[countFields];
	int numberFieldValue[countFields];
	int countNumberFields;
	int selectedNumberField;
	int selectedNumberFieldFirstInput;
	
	NSPoint separatorPoint[countFields];
	NSString *separator[countFields];
	
	NSNumberFormatter *formatter1, *formatter2, *formatter3;
}

- (void)rotateSelectionBy:(int)i;

- (void)setType:(int)value;
- (void)setLocator:(NSUInteger)value;
- (void)setLocators;

- (void)setNumber:(int)num reset:(BOOL)reset;
- (void)commitValues;

// mathematics
- (void)locatorAtIndex:(int)locIndex toNumberFieldsStartingAtIndex:(int)fieldIndex;
- (void)numberFieldsStartingAtIndex:(int)fieldIndex toLocatorAtIndex:(int)locIndex;

@end


typedef enum _CounterType
{
	H_M_S_CounterType = 0,
	Samples_CounterType = 1
} CounterType;

