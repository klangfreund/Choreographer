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
    int character = [[event charactersIgnoringModifiers] characterAtIndex:0];
    
    //carriage return (36) or enter (76)
	if(keyCode == 36 || keyCode == 76)
	{
			if([event modifierFlags] & NSCommandKeyMask)
				[playbackController returnToZero];
			else
				[playbackController stopPlayback];
    }
    
    // spacebar = PLAY / PAUSE
    else if(keyCode == 49)
			[playbackController startStop];
			
    // 1
    else if(keyCode == 18)
    {
        if([event modifierFlags] & NSAlternateKeyMask)
                [document setValue:[NSNumber numberWithInt:0] forKeyPath:@"projectSettings.arrangerDisplayMode"];
    }
    
    // 2
    else if(keyCode == 19)
    {
        if([event modifierFlags] & NSAlternateKeyMask)
                [document setValue:[NSNumber numberWithInt:1] forKeyPath:@"projectSettings.arrangerDisplayMode"];
    }
    
    // 'z' or 'Z'
    else if(character == 90 || character == 122)
    {
        if(document.keyboardModifierKeys == modifierShift)
                [document zoomToFitContent:self];
            else if(document.keyboardModifierKeys == modifierAlt)
                [document zoomToFitSelection:self];
    }       
 
    else  [[self nextResponder] keyDown:event];
}

@end
