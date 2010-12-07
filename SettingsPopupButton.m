//
//  SettingsPopupButton.m
//  Choreographer
//
//  Created by Philippe Kocher on 09.06.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "SettingsPopupButton.h"


@implementation SettingsPopupButton

- (void)awakeFromNib
{
	NSArray *menuItems = [[self menu] itemArray];
	
	for(NSMenuItem *menuItem in menuItems)
	{
		[menuItem setTarget:self];
		[menuItem setAction:@selector(menuAction:)];
		[menuItem setState:NSOffState];
	}
}


- (void)setModel:(id)aModel keyPath:(NSString *)aString
{
	model = aModel;
	keyPath = aString;
	
	id item = [[self menu] itemWithTag:[[model valueForKeyPath:keyPath] integerValue]];
	if(!item)
	{
		item = [[[self menu] itemArray] objectAtIndex:0];
	}

	[self menuAction:item];
}

- (void)setModel:(id)aModel key:(NSString *)aString
{
	[self setModel:aModel keyPath:aString];
}


- (void)menuAction:(id)sender
{
	currentItem = sender;
	
	[self selectItemWithTag:[currentItem tag]];
	
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
