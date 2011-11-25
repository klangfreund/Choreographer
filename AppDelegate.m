//
//  AppDelegate.m
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "AppDelegate.h"
#import "RadarEditorWindowController.h"
#import "TableEditorWindowController.h"
#import "TimelineEditorWindowController.h"
#import "MarkersWindowController.h"
#import "AudioEngine.h"


@implementation AppDelegate

@synthesize currentProjectDocument;

- (IBAction)newDocument:(id)sender
{
	if([[[NSDocumentController sharedDocumentController] documents] count])
	{
		NSLog(@"only one open file at once");
		NSBeep();
	}
	else
	{
		// a new document is immediately named and saved
		// (important to store the relative paths of audio files)
		
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"chproj",nil]];
		[savePanel setNameFieldStringValue:@"Untitled Project"];
		[savePanel setExtensionHidden:YES];

		// accessory view (project sample rate)
		[self setValue:[NSNumber numberWithInt:44100] forKey:@"projectSampleRate"];
		[savePanel setAccessoryView:openPanelAccessoryView];
		
		if([savePanel runModal] == NSOKButton)
		{
			[[NSDocumentController sharedDocumentController] newDocument:sender];
			[currentProjectDocument setValue:[NSNumber numberWithInt:projectSampleRate] forKeyPath:@"projectSampleRate"];
			
			// currentProjectDocument has been set in the ProjectDocuments init method
			[currentProjectDocument saveToURL:[savePanel URL]
									   ofType:[currentProjectDocument fileType]
							 forSaveOperation:NSSaveOperation
									 delegate:nil
							  didSaveSelector:nil
								  contextInfo:nil];
		}
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

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	[startupSplashWindow center];
	[startupSplashWindow makeKeyAndOrderFront:nil];
	[startupSplashWindow setStyleMask:NSBorderlessWindowMask];
	[startupSplashWindow setBackgroundColor:[NSColor whiteColor]];	
	[startupSplashWindow setAlphaValue:0.85];

	[startupStatusTextField setStringValue:@"Starting Up"];
	
	NSString *version = [NSString stringWithFormat:@"Version: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	[self setValue:version forKey:@"versionString"];
	[startupSplashWindow display];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// setting the defaults
	[startupStatusTextField setStringValue:@"Reading Preferences"];
	[startupSplashWindow display];
	
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
	[startupStatusTextField setStringValue:@"Initialize Audio Engine"];
	[startupSplashWindow display];

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



    // show editor windows as stored in preferences
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"radarEditorVisible"])
        [[RadarEditorWindowController sharedRadarEditorWindowController] showWindow:nil];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"tableEditorVisible"])
        [[TableEditorWindowController sharedTableEditorWindowController] showWindow:nil];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"timelineEditorVisible"])
        [[TimelineEditorWindowController sharedTimelineEditorWindowController] showWindow:nil];

	[startupSplashWindow orderOut:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)notification
{
	// unsaved changes in the audio engine?
//	return NSTerminateLater;
	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	// release and free the audio engine
	[AudioEngine release];
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

- (IBAction)showMarkersWindow:(id)sender
{
	[[MarkersWindowController sharedMarkersWindowController] showWindow:nil];
}


- (void)updateWindowsMenu:(NSNotification *)notification
{
	NSInteger tag;
	id windowController = [[notification object] windowController];
	
	if(windowController == [[currentProjectDocument windowControllers] objectAtIndex:0])//[currentProjectDocument windowController])
		tag = 1;
	else if(windowController == [RadarEditorWindowController sharedRadarEditorWindowController])
		tag = 2;
	else if(windowController == [TableEditorWindowController sharedTableEditorWindowController])
		tag = 3;
	else if(windowController == [TimelineEditorWindowController sharedTimelineEditorWindowController])
		tag = 4;
	else if(windowController == [MarkersWindowController sharedMarkersWindowController])
		tag = 5;
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
