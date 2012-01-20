//
//  SettingsPopupButton.m
//  Choreographer
//
//  Created by Philippe Kocher on 09.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
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

- (void)dealloc
{
    [model removeObserver:self forKeyPath:keyPath];
    [super dealloc];
}


- (void)setModel:(id)aModel keyPath:(NSString *)aString
{
    if(model)
        [model removeObserver:self forKeyPath:keyPath];

	model = aModel;
	keyPath = aString;
    
    [model addObserver:self forKeyPath:keyPath options:0 context:nil];
	
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

- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    if([[object valueForKeyPath:path] intValue] != selectedTag)
    {
        selectedTag = [[object valueForKeyPath:path] intValue];
        [self selectItemWithTag:selectedTag];
    }
}

@end
