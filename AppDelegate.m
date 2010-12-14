//
//  AppDelegate.m
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "AppDelegate.h"
#import "RadarEditorWindowController.h"
#import "TableEditorWindowController.h"
#import "TimelineEditorWindowController.h"
#import "AudioEngine.h"


@implementation AppDelegate

- (IBAction)newDocument:(id)sender
{
	if([[[NSDocumentController sharedDocumentController] documents] count])
	{
		NSLog(@"only one open file at once");
		NSBeep();
	}
	else
	{
		[[NSDocumentController sharedDocumentController] newDocument:sender];
	}
}

- (IBAction)openDocument:(id)sender
{
	if([[[NSDocumentController sharedDocumentController] documents] count])
	{
		NSLog(@"only one open file at once");
		NSBeep();
	}
	else
	{
		[[NSDocumentController sharedDocumentController] openDocument:sender];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// setting the defaults
	
	NSColor *audioRegionColor = [NSColor colorWithCalibratedRed: 0.2 green: 0.6 blue: 1.0 alpha: 1];
	NSColor *groupRegionColor = [NSColor colorWithCalibratedRed: 0.2 green: 1.0 blue: 0.2 alpha: 1];
	NSColor *trajectoryRegionColor = [NSColor colorWithCalibratedRed: 0.7 green: 0.0 blue: 0.7 alpha: 1];
	
	NSData *audioRegionColorData =[NSArchiver archivedDataWithRootObject:audioRegionColor];
	NSData *groupRegionColorData =[NSArchiver archivedDataWithRootObject:groupRegionColor];
	NSData *trajectoryRegionColorData =[NSArchiver archivedDataWithRootObject:trajectoryRegionColor];
    
	NSArray *keys = [NSArray arrayWithObjects:@"audioRegionColor", @"groupRegionColor", @"trajectoryRegionColor", nil];
	NSArray *objects = [NSArray arrayWithObjects:audioRegionColorData, groupRegionColorData, trajectoryRegionColorData, nil];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
 	
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];	
	

	[[NSUserDefaultsController sharedUserDefaultsController] setAppliesImmediately:YES];

	// instantiate the audio engine
	[AudioEngine sharedAudioEngine];

	// instantiate the editor content object (= data model)
	// to have it ready when the first editor is opened
	[EditorContent sharedEditorContent];


	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateWindowsMenu:)
												 name:NSWindowDidBecomeKeyNotification object:nil];		

	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateWindowsMenu:)
												 name:NSWindowDidResignKeyNotification object:nil];		
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{
	// unsaved changes in the audio engine?
//	return NSTerminateLater;
	return NSTerminateNow;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (IBAction)showArrangerWindow:(id)sender
{
	NSWindowController *windowController = [[[[NSDocumentController sharedDocumentController] currentDocument] windowControllers] objectAtIndex:0];
	[[windowController window] makeKeyAndOrderFront:nil];
	
// works only when all other windows are instances of NSPanel
// sharedDocumentController returns nil when another window is active...
}


- (IBAction)showRadarEditorWindow:(id)sender;
{
	[[RadarEditorWindowController sharedRadarEditorWindowController] showWindow:nil];
}

- (IBAction)showTableEditorWindow:(id)sender
{
	[[TableEditorWindowController sharedTableEditorWindowController] showWindow:nil];
}

- (IBAction)showTimelineEditorWindow:(id)sender
{
	[[TimelineEditorWindowController sharedTimelineEditorWindowController] showWindow:nil];
}

- (void)updateWindowsMenu:(NSNotification *)notification
{
	NSInteger tag;
	id windowController = [[notification object] windowController];
	
	if(windowController == [RadarEditorWindowController sharedRadarEditorWindowController])
		tag = 2;
	else if(windowController == [TableEditorWindowController sharedTableEditorWindowController])
		tag = 3;
	else if(windowController == [TimelineEditorWindowController sharedTimelineEditorWindowController])
		tag = 4;
	else
		return;
	
	NSMenu *menu = [[NSApplication sharedApplication] windowsMenu];

	if([[notification object] isKeyWindow])
		[[menu itemWithTag:tag] setState:NSOnState];
	else
		[[menu itemWithTag:tag] setState:NSOffState];
}

- (void)keyDown:(NSEvent *)event
{
//	unsigned short keyCode = [event keyCode];
//	NSLog(@"App key code: %d ", keyCode);
}


@end
