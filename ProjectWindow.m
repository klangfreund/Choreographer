//
//  ProjectWindow.m
//  Choreographer
//
//  Created by Philippe Kocher on 04.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ProjectWindow.h"
#import "CHProjectDocument.h"
#import "PlaybackController.h"


@implementation ProjectWindow
- (void)awakeFromNib
{
	// synchronize scroll views
	[rulerScrollView setSynchronizedScrollView:arrangerScrollView];
	[arrangerScrollView setSynchronizedScrollView:rulerScrollView];
}

- (void)becomeKeyWindow
{
	[[self firstResponder] flagsChanged:nil];  // to "reset" the modifier keys...

	[(CHProjectDocument *)document selectionInArrangerDidChange];

	[super becomeKeyWindow];
}

- (void) dealloc
{
	[super dealloc];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
	[super setFrame:frameRect display:flag];
}


#pragma mark -
#pragma mark keyboard events
// -----------------------------------------------------------

- (void)flagsChanged:(NSEvent *)event
{
	if([event modifierFlags] & NSControlKeyMask)
		document.keyboardModifierKeys = modifierControl;
	else if([event modifierFlags] & NSShiftKeyMask && !([event modifierFlags] & NSControlKeyMask) && !([event modifierFlags] & NSAlternateKeyMask) && !([event modifierFlags] & NSCommandKeyMask))
		document.keyboardModifierKeys = modifierShift;
	else if(!([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSControlKeyMask) && [event modifierFlags] & NSAlternateKeyMask && !([event modifierFlags] & NSCommandKeyMask))
		document.keyboardModifierKeys = modifierAlt;
	else if(!([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSControlKeyMask) && !([event modifierFlags] & NSAlternateKeyMask) && [event modifierFlags] & NSCommandKeyMask)
		document.keyboardModifierKeys = modifierCommand;
	else if(!([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSControlKeyMask) && [event modifierFlags] & NSAlternateKeyMask && [event modifierFlags] & NSCommandKeyMask)
		document.keyboardModifierKeys = modifierAltCommand;
	else if([event modifierFlags] & NSShiftKeyMask && !([event modifierFlags] & NSControlKeyMask) && [event modifierFlags] & NSAlternateKeyMask && [event modifierFlags] & NSCommandKeyMask)
		document.keyboardModifierKeys = modifierShiftAltCommand;

	else
		document.keyboardModifierKeys = modifierNone;
}	


- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	NSLog(@"ProjectWindow key code: %d ", keyCode);
	
//	short num = -1;
	
	switch(keyCode)
	{
		//carriage return
		case 36:
		// enter
		case 76:
			
			if([event modifierFlags] & NSCommandKeyMask)
				[playbackController returnToZero];
			else
				[playbackController stopPlayback];
			break;		
			

		// spacebar = PLAY / PAUSE
		case 49:
			[playbackController startStop];
			break;
			
		default:
			[[self nextResponder] keyDown:event];

		// numbers
/*		case 18:
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
			num = 6; break;
		case 23:
		case 88:
			num = 5; break;
		case 25:
		case 89:
			num = 9; break;
		case 26:
		case 91:
			num = 7; break;
		case 28:
		case 92:
			num = 8; break;
		case 29:
		case 82:
			num = 0; break;

		// tab or dot
		case 48:
		case 47:
		case 65:
			break; */
			
	}
}

@end
