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
	id                          project;
    IBOutlet NSArrayController  *markersArrayController;
    NSArray                     *markerSortDescriptors;
}

@property (assign) NSArray *markerSortDescriptors;

+ (id)sharedMarkersWindowController;

- (NSArray *)markers;

// IB Actions
- (IBAction)addMarker:(id)sender;
- (IBAction)deleteSelectedMarker:(id)sender;

// actions
- (void)update;
- (void)synchronizeWithProject:(id)project;
- (id)newMarkerWithTime:(NSUInteger)time;
- (void)deleteMarker:(id)marker;

- (NSUInteger)locatorGreaterThan:(NSUInteger)loc;
- (NSUInteger)locatorLessThan:(NSUInteger)loc;
@end
