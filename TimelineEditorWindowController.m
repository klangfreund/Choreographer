//
//  TimelineEditorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "TimelineEditorWindowController.h"

static TimelineEditorWindowController *sharedTimelineEditorWindowController = nil;

@implementation TimelineEditorWindowController

+ (id)sharedTimelineEditorWindowController
{
    if (!sharedTimelineEditorWindowController)
	{
        sharedTimelineEditorWindowController = [[TimelineEditorWindowController alloc] init];
    }
    return sharedTimelineEditorWindowController;
}


- (id)init
{
	self = [self initWithWindowNibName:@"TimelineEditor"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"TimelineEditor"];
		
        // init zoom factor
        float zoomFactorX = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];
        
        if(zoomFactorX == 0)
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:1.0] forKey:@"timelineEditorZoomFactorX"];
    }
    return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	// synchronize scroll views
	[rulerScrollView setSynchronizedScrollView:arrangerScrollView];
	[arrangerScrollView setSynchronizedScrollView:rulerScrollView];	
}

//- (void)dealloc
//{
//	[super dealloc];
//}


- (void)becomeKeyWindow
{	
	[self flagsChanged:nil];  // to "reset" the modifier keys...
}


- (void)windowDidResignKey:(NSNotification *)notification
{
	for(BreakpointView *bpView in [view valueForKey:@"breakpointViews"])
	{
		[bpView setIsKey:NO];	
	}

	[view setNeedsDisplay:YES];
}

- (void)refreshView
{
    if(![[self window] isVisible]) return;
    
	NSString *info = [[EditorContent sharedEditorContent] valueForKey:@"infoStringTimelineEditor"];
	[infoTextField setStringValue:info];

    //	NSLog(@"Timeline Editor refresh view");

	TrajectoryItem *tempTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	
	if (trajectory != tempTrajectory)
	{
		trajectory = tempTrajectory;
	} 
	
    [view setupSubviews];
	[view setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (IBAction)xZoomIn:(id)sender
{
	float zoomFactorX = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];
	zoomFactorX *= 1.2;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:zoomFactorX] forKey:@"timelineEditorZoomFactorX"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"timelineEditorZoomFactorDidChange" object:self];	
}
     
- (IBAction)xZoomOut:(id)sender
{
	float zoomFactorX = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];

    zoomFactorX /= 1.2;
    zoomFactorX = zoomFactorX < 0.0001 ? 0.0001 : zoomFactorX;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:zoomFactorX] forKey:@"timelineEditorZoomFactorX"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"timelineEditorZoomFactorDidChange" object:self];	
}
 
 - (IBAction)yZoomIn:(id)sender
{	
    //	float zoomFactorY = [[projectSettings valueForKey:@"arrangerZoomFactorY"] floatValue];
//    zoomFactorY *= 1.2;
//    zoomFactorY = zoomFactorY > 10 ? 10 : zoomFactorY;
//    
//    [self setNeedsDisplay:YES];
}
     
 - (IBAction)yZoomOut:(id)sender
{	
    //	float zoomFactorY = [[projectSettings valueForKey:@"arrangerZoomFactorY"] floatValue];
//    zoomFactorY /= 1.2;
//    zoomFactorY = zoomFactorY < 0.1 ? 0.1 : zoomFactorY;
//    
//    [self setNeedsDisplay:YES];
}

@end
