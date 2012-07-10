//
//  MarkersWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 20.12.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "MarkersWindowController.h"

static MarkersWindowController *sharedMarkersWindowController = nil;


@implementation MarkersWindowController

@synthesize markerSortDescriptors;

+ (id)sharedMarkersWindowController
{
    if (!sharedMarkersWindowController)
	{
        sharedMarkersWindowController = [[MarkersWindowController alloc] init];
    }
    return sharedMarkersWindowController;
}

- (id)init
{
	self = [self initWithWindowNibName:@"MarkersWindow"];
	if(self)
	{
        [self setWindowFrameAutosaveName:@"MarkersWindow"];
        id markerSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
        markerSortDescriptors = [[NSArray arrayWithObject:markerSortDescriptor] retain];

    }
    return self;
}

-(void)dealloc
{
    [markerSortDescriptors release];
    [super dealloc];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    [self synchronizeWithProject:project];
}

#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------


- (NSArray *)markers
{
    NSError *error;
    NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext *context = [[[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument"] managedObjectContext];
    if(context)
    {
        NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Marker" inManagedObjectContext:context];
        NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES] autorelease];
        
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        [request setEntity:entityDescription];
        [request setReturnsObjectsAsFaults:NO];
        
        id markers = [context executeFetchRequest:request error:&error];
        return markers;
    }
    else return nil;
}

- (NSUInteger)locatorGreaterThan:(NSUInteger)loc
{
    for(id marker in [self markers])
    {
        if([[marker valueForKey:@"time"] unsignedIntegerValue] > loc)
            return [[marker valueForKey:@"time"] unsignedIntegerValue];
    }
    return NSNotFound;
}

- (NSUInteger)locatorLessThan:(NSUInteger)loc
{
    id lastMarker = nil;
    
    for(id marker in [self markers])
    {
        if(lastMarker && [[marker valueForKey:@"time"] unsignedIntegerValue] >= loc)
            return [[lastMarker valueForKey:@"time"] unsignedIntegerValue];

        lastMarker = marker;
    }
    return NSNotFound;
}

#pragma mark -
#pragma mark IB actions
// -----------------------------------------------------------

- (void)addMarker:(id)sender
{
    [self newMarkerWithTime:0];
}

- (void)deleteSelectedMarker:(id)sender
{
    id markers = [markersArrayController selectedObjects];
    
    if([markers count])
        [self deleteMarker:[markers objectAtIndex:0]];
}

#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)update
{
    [markersArrayController setContent:[self markers]];
}

- (void)synchronizeWithProject:(id)proj
{
    project = proj;
    if(project)
        [markersArrayController setContent:[self markers]];
    else
        [markersArrayController setContent:nil];
}

- (id)newMarkerWithTime:(NSUInteger)time
{
    NSManagedObject* newMarker;
	NSManagedObjectContext *context = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
    
    if(context)
    {
        newMarker = [NSEntityDescription insertNewObjectForEntityForName:@"Marker" inManagedObjectContext:context];
    
        [newMarker setValue:[NSNumber numberWithUnsignedInteger:time] forKey:@"time"];
        [newMarker setValue:@"marker" forKey:@"name"];
    
        [self update];
    }
    
    return newMarker;
}

- (void)deleteMarker:(id)marker
{    
    NSManagedObjectContext *context = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
    [context deleteObject:marker];

    [self synchronizeWithProject:project];
}


#pragma mark -
#pragma mark table view delegate method
// -----------------------------------------------------------

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
 	NSArray *selection = [markersArrayController selectedObjects];
    if([selection count])
    {
        id document = [[NSDocumentController sharedDocumentController] currentDocument];
        id arrangerView = [document valueForKey:@"arrangerView"];
    
        [arrangerView performSelector:@selector(recallMarker:) withObject:[[selection objectAtIndex:0] valueForKey:@"time"]];
    }
}


@end
