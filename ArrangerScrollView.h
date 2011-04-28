//
//  ArrangerScrollView.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.01.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ArrangerScrollView : NSScrollView
{
	IBOutlet NSButton *xZoomInButton;
	IBOutlet NSButton *xZoomOutButton;
	IBOutlet NSButton *yZoomInButton;
	IBOutlet NSButton *yZoomOutButton;

    NSScrollView* synchronizedScrollView;
}

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;
- (void)stopSynchronizing;

@end
