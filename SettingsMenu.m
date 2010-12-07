//
//  SettingsMenu.m
//  Choreographer
//
//  Created by Philippe Kocher on 31.03.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "SettingsMenu.h"


@implementation SettingsMenu

- (void)awakeFromNib
{
	NSEnumerator *enumerator = [[self itemArray] objectEnumerator];
	NSMenuItem *menuItem;
	
	while(menuItem = [enumerator nextObject])
	{
		[menuItem setTarget:self];
		[menuItem setAction:@selector(menuAction:)];
		[menuItem setState:NSOffState];
	}

	id item = [self itemAtIndex:0];
	[self menuAction:item];
}


- (void)setModel:(id)aModel keyPath:(NSString *)aString
{
	model = aModel;
	keyPath = aString;
	
	id item = [self itemWithTag:[[model valueForKeyPath:keyPath] integerValue]];
	if(!item)
	{
		item = currentItem;
	}
	
	[self menuAction:item];
}

- (void)setModel:(id)aModel key:(NSString *)aString
{
	[self setModel:aModel keyPath:aString];
}


- (void)menuAction:(id)sender
{
	[currentItem setState:NSOffState];
	currentItem = sender;
	[currentItem setState:NSOnState];
	
	selectedTag = [currentItem tag];

	// update model
	// (exclude from undo)
	id document = [[NSDocumentController sharedDocumentController] currentDocument];
	[[[document managedObjectContext] undoManager] disableUndoRegistration];
	[model setValue:[NSNumber numberWithInt:selectedTag] forKeyPath:keyPath];
	[[document managedObjectContext] processPendingChanges];
	[[[document managedObjectContext] undoManager] enableUndoRegistration];
}

@end
