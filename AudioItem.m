//
//  AudioRegion.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "AudioItem.h"
#import "CHGlobals.h"



@implementation AudioItem

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	NSLog(@"AudioItem awakeFromInsert, path: %@", [self valueForKeyPath:@"audioFile.filePath"]);
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	NSLog(@"AudioItem awakeFromFetch, path: %@", [self valueForKeyPath:@"audioFile.filePath"]);
}

- (void)dealloc
{
	NSLog(@"AudioItem: dealloc");
	[super dealloc];
}

@end
