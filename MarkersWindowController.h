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
	//IBOutlet NSTableView        *markersTableView;
    IBOutlet NSArrayController  *markersArrayController;
    NSArray                     *markerSortDescriptors;
}

@property (assign) NSArray *markerSortDescriptors;

+ (id)sharedMarkersWindowController;

- (NSManagedObjectContext *)managedObjectContext;
- (NSArray *)markers;

// actions
- (void)newMarkerWithName:(NSString *)name time:(NSUInteger)time;
- (void)deleteMarker:(id)marker;

@end
