//
//  SmallTimelinePanel.h
//  Choreographer
//
//  Created by Philippe Kocher on 06.11.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SmallTimelinePanel : NSObject
{
    NSWindow *window;
	NSView *smallTimelinePanelView;
}

+ (id)sharedSmallTimelinePanel;
+ (void) release;

- (void)editBreakpoint:(id)bp trajectory:(id)tr event:(NSEvent *)theEvent;

@end


@interface SmallTimelinePanelView : NSView

@end