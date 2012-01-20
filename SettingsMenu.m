//
//  SettingsMenu.m
//  Choreographer
//
//  Created by Philippe Kocher on 31.03.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "SettingsMenu.h"


@implementation SettingsMenu

- (void)awakeFromNib
{
	models = [NSMutableDictionary new];
	keyPaths = [NSMutableDictionary new];
	currentItems = [NSMutableDictionary new];
	highestIndexPerSection = [NSMutableArray new];
	int index;
	
	NSMenuItem *menuItem;
	
	for(menuItem in [self itemArray])
	{
		index = [self indexOfItem:menuItem];
		
		if(![menuItem isSeparatorItem])
		{
			[menuItem setTarget:self];
			[menuItem setAction:@selector(menuAction:)];
			
			if(index == 0)
			{
				[menuItem setState:NSOnState];
			}
			else if(index > 0  && [[self itemAtIndex:index - 1] isSeparatorItem])
			{
				[highestIndexPerSection addObject:[NSNumber numberWithInt:index - 2]];
				[menuItem setState:NSOnState];
			}
			else
			{
				[menuItem setState:NSOffState];
			}
		}
	}

	[highestIndexPerSection addObject:[NSNumber numberWithInt:index]];
}

- (void) dealloc
{
	[models release];
	[keyPaths release];
	[currentItems release];
	[highestIndexPerSection release];
	[super dealloc];
}



- (void)setModel:(id)aModel key:(NSString *)aString
{
	[self setModel:aModel keyPath:aString index:0];
}

- (void)setModel:(id)aModel key:(NSString *)aString index:(NSInteger)i
{
	[self setModel:aModel keyPath:aString index:i];
}

- (void)setModel:(id)aModel keyPath:(NSString *)aString
{
	[self setModel:aModel keyPath:aString index:0];
}

- (void)setModel:(id)aModel keyPath:(NSString *)aString index:(NSInteger)i
{
    if([models objectForKey:[NSNumber numberWithInt:i]])
        [[models objectForKey:[NSNumber numberWithInt:i]] removeObserver:self forKeyPath:[keyPaths objectForKey:[NSNumber numberWithInt:i]]];

	[models setObject:aModel forKey:[NSNumber numberWithInt:i]];
	[keyPaths setObject:aString forKey:[NSNumber numberWithInt:i]];

    [aModel addObserver:self forKeyPath:aString options:0 context:nil];

    id model = aModel;
	int loIndex = i == 0 ? 0 : [[highestIndexPerSection objectAtIndex:i - 1] intValue] + 2;
	int hiIndex = [[highestIndexPerSection objectAtIndex:i] intValue];
	id item = [self itemAtIndex:loIndex];
	

	for(NSMenuItem *tempItem in [self itemArray])
	{
		if([self indexOfItem:tempItem] >= loIndex && [self indexOfItem:tempItem] <= hiIndex &&
		   [tempItem tag] == [[model valueForKeyPath:aString] integerValue])
		{
			item = tempItem;
			break;
		}
	}
	
	[self menuAction:item];
}


- (void)menuAction:(id)sender
{
	int index = [self indexOfItem:sender];
	int section = 0;
	
	for(NSNumber *highestIndex in highestIndexPerSection)
	{
		if(index > [highestIndex intValue])
			section++;
	}
		
	int loIndex = section == 0 ? 0 : [[highestIndexPerSection objectAtIndex:section-1] intValue];
	int hiIndex = [[highestIndexPerSection objectAtIndex:section] intValue];
	int i;
	NSMenuItem *item;
	NSInteger selectedTag;
	
	for(i=loIndex;i<=hiIndex;i++)
	{
		item = [self itemAtIndex:i];
		[item setState:NSOffState];
		
		if(item == sender)
		{
			[currentItems setObject:sender forKey:[NSNumber numberWithInt:section]];
			[sender setState:NSOnState];
			selectedTag = [sender tag];
		}
	}

	// update model
	// (exclude from undo)
	id document = [[NSDocumentController sharedDocumentController] currentDocument];
	id model = [models objectForKey:[NSNumber numberWithInt:section]];
	id keyPath = [keyPaths objectForKey:[NSNumber numberWithInt:section]];
				
	[[[document managedObjectContext] undoManager] disableUndoRegistration];
	[model setValue:[NSNumber numberWithInt:selectedTag] forKeyPath:keyPath];
	[[document managedObjectContext] processPendingChanges];
	[[[document managedObjectContext] undoManager] enableUndoRegistration];
}

- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    //NSLog(@"observe: %@", object);
}


@end
