//
//  LoopCounterView.h
//  Choreographer
//
//  Created by Philippe Kocher on 25.03.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CounterView.h"

@interface LoopCounterView : CounterView
{}

- (void)update:(NSNotification *)notification;
@end
