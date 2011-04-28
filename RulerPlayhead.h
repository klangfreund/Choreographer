//
//  RulerPlayhead.h
//  Choreographer
//
//  Created by Philippe Kocher on 06.08.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Playhead.h"


@interface RulerPlayhead : Playhead
{
	IBOutlet id playbackController;

	BOOL inDraggingSession;
}
@property BOOL inDraggingSession;
@end