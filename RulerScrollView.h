//
//  RulerScrollView.h
//  Choreographer
//
//  Created by Philippe Kocher on 16.02.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RulerScrollView : NSScrollView
{
    NSScrollView* synchronizedScrollView; // not retained
}
 
- (void)setSynchronizedScrollView:(NSScrollView*)scrollview;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;
- (void)stopSynchronizing;

@end
