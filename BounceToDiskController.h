//
//  BounceToDiskController.h
//  Choreographer
//
//  Created by Philippe Kocher on 04.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BounceToDiskController : NSObject
{
	IBOutlet NSView *bouncePanelAccessoryView;

	NSInteger bounceStart;
	NSInteger bounceEnd;
	NSInteger bounceMode;
	
	id document;
}

- (void)bounceToDisk:(id)doc;

- (void)setBounceMode:(int)val;
- (void)setBounceStart:(NSInteger)val;
- (void)setBounceEnd:(NSInteger)val;

@end
