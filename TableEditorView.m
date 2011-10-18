//
//  TableEditorView.m
//  Choreographer
//
//  Created by Philippe Kocher on 17.11.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "TableEditorView.h"
#import "TableEditorWindowController.h"


@implementation TableEditorView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

//- (BOOL)becomeFirstResponder
//{
//	return YES;
//}

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];

	printf("\nTableEditorView key code: %d", keyCode);

	switch (keyCode)
	{
        case 51:	// BACKSPACE
        case 117:	// DELETE
            
            if(displayMode == regionDisplayMode)
            {
                [[EditorContent sharedEditorContent] setSelectedPointsTo:[SpatialPosition positionWithX:0 Y:0 Z:0]];
            }
            else if(displayMode == trajectoryDisplayMode)
            {
                [[EditorContent sharedEditorContent] deleteSelectedPoints];
            }
            break;

		default:
			[[[[[[NSDocumentController sharedDocumentController] currentDocument] windowControllers] objectAtIndex:0] window] keyDown:event];
	}
}
	
@end
