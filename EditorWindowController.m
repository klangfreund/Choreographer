//
//  EditorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 25.10.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "EditorWindowController.h"

/*
	abstract superclass for all editor window controllers
*/

@implementation EditorWindowController

- (void)awakeFromNib
{
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateContent:)
												 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateContent:)
												 name:@"updateEditors" object:nil];
										  

	tempEditorSelection = [[NSMutableSet alloc] init];
	
	[[self window] setExcludedFromWindowsMenu:YES];
	
	[self updateContent:nil];
}

- (void) dealloc
{
	NSLog(@"EditorWindowController: dealloc");
	
	[tempEditorSelection release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[super dealloc];
}	

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	// return the document's undo manager
	// (controller acts as delegate of the window)
	return [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
}

- (void)updateContent:(NSNotification *)notification
{
	NSString *info = [[EditorContent sharedEditorContent] valueForKey:@"infoString"];
	[infoTextField setStringValue:info];
	
	if([notification object] != self)
		[self refreshView];
}

// abstract method
- (void)refreshView{}
@end
