//
//  MarkersWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 20.12.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MarkersWindowController : NSWindowController
{
	IBOutlet NSTableView	*markersTableView;
}

+ (id)sharedMarkersWindowController;

@end
