//
//  TableEditorView.m
//  Choreographer
//
//  Created by Philippe Kocher on 17.11.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "TableEditorView.h"
#import "TableEditorWindowController.h"


@implementation TableEditorView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
//	printf("\nTableEditorView -- becomeFirstResponder...");
	return YES;
}

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	printf("\nTableEditorView key code: %d", keyCode);

	switch (keyCode)
	{
	
		default:
			[[[[[[NSDocumentController sharedDocumentController] currentDocument] windowControllers] objectAtIndex:0] window] keyDown:event];
	}
}
	
@end
