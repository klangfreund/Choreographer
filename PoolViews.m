//
//  PoolViews.m
//  Choreographer
//
//  Created by Philippe Kocher on 17.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "PoolViews.h"


@implementation PoolView : NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	[super resizeSubviewsWithOldSize:oldBoundsSize];
	
	if(oldBoundsSize.width < 10)
	{
		NSRect r = [tabControl frame];
		
		r.origin.x = [self frame].size.width * 0.5 - r.size.width * 0.5;
		[tabControl setFrame:r];
	}
}

@end


@implementation PoolOutlineView

-(BOOL)becomeFirstResponder
{
//    NSLog(@"Pool Outline View -- becomeFirstResponder...");
	hasFocus = YES;
	return YES;
}

- (BOOL)resignFirstResponder
{
	hasFocus = NO;
	return YES;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	[super textDidEndEditing:notification];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewSelectionDidChangeNotification object:self];
}

- (void)mouseDown:(NSEvent *)event
{
    if([event modifierFlags] & NSAlternateKeyMask)
    { 
        NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
        float y = localPoint.y - 5;
        float h = [self rowHeight];
        int index = y/h;
        
        [(PoolViewController *)[self delegate] prelisten:self index:index];
    }
    else
    {
        [super mouseDown:event];   
    }
}

- (void)mouseUp:(NSEvent *)event
{
    [(PoolViewController *)[self delegate] prelisten:self index:-1];   
}

@end


@implementation PoolTableView

-(BOOL)becomeFirstResponder
{
	hasFocus = YES;
	return YES;
}

- (BOOL)resignFirstResponder
{
	hasFocus = NO;
	return YES;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	[super textDidEndEditing:notification];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewSelectionDidChangeNotification object:self];
}

- (void)mouseDown:(NSEvent *)event
{
    if([event modifierFlags] & NSAlternateKeyMask)
    { 
        NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
        float y = localPoint.y - 5;
        float h = [self rowHeight];
        int index = y/h;
                
        [(PoolViewController *)[self delegate] prelisten:self index:index];
    }
    else
    {
        [super mouseDown:event];   
    }
}

- (void)mouseUp:(NSEvent *)event
{
    [(PoolViewController *)[self delegate] prelisten:self index:-1];   
}


@end