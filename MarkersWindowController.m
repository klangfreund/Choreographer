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

#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------


// binding in IB
- (NSManagedObjectContext *)managedObjectContext
{
	id document = [[NSDocumentController sharedDocumentController] currentDocument];
	return [document managedObjectContext];
}

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


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)newMarkerWithName:(NSString *)name time:(NSUInteger)time
{
    NSManagedObject* newMarker;
	NSManagedObjectContext *context = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
    
    newMarker = [NSEntityDescription insertNewObjectForEntityForName:@"Marker" inManagedObjectContext:context];
    
    [newMarker setValue:[NSNumber numberWithUnsignedInteger:time] forKey:@"time"];
    [newMarker setValue:name forKey:@"name"];
}

- (void)deleteMarker:(id)marker
{    
    NSManagedObjectContext *context = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
    [context deleteObject:marker];
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
