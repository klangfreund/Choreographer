//
//  Playhead.h
//  Choreographer
//
//  Created by Philippe Kocher on 12.10.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Playhead : NSView
{
	IBOutlet id document;

	unsigned long	locator;
	float			zoomFactorX;
	float			resolution;
}

- (void)setOrigin;
- (void)setZoomFactor:(NSNotification *)notification;
- (void)setLocator:(unsigned long)value;

@end
