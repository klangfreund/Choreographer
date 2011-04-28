//
//  EditorContent.h
//  Choreographer
//
//  Created by Philippe Kocher on 05.11.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "TrajectoryItem.h"


@interface EditorContent : NSObject
{	
	NSArray *selectedAudioRegions;
	NSArray *allAudioRegions;
	NSArray *displayedAudioRegions;
	
	NSMutableArray *displayedTrajectories;
	
	TrajectoryItem *editableTrajectory;

	EditorDisplayMode displayMode;

	NSMutableSet *editorSelection;
	
	NSMutableString *infoString;
	
	unsigned long locator;
}

+ (id)sharedEditorContent;

- (void)synchronizeWithArranger:(id)arranger pool:(id)pool;
- (void)synchronizeWithLocator:(unsigned long)value;

- (void)setDisplayedItems;

- (void)deleteSelectedPoints;
- (void)updateModelForSelectedPoints;

@end
