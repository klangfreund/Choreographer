//
//  ProjectAudioSettingsWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 16.01.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import "ProjectAudioSettingsWindowController.h"
#import "AudioEngine.h"

@implementation ProjectAudioSettingsWindowController

- (id)init
{
	self = [self initWithWindowNibName:@"ProjectAudioSettingsWindow"];
	if(self)
	{        
        [self setWindowFrameAutosaveName:@"ProjectAudioSettingsWindow"];

    	[self addObserver:self forKeyPath:@"ambisonicsOrder" options:0 context:nil];

    	[self addObserver:self forKeyPath:@"distanceBasedAttenuation" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedFiltering" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedDelay" options:0 context:nil];

        //audioEngine = [AudioEngine sharedAudioEngine];
    }
    
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];

    document = [[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument"];
    [self setValue:[document valueForKeyPath:@"projectSettings.ambisonicsOrder"] forKeyPath:@"ambisonicsOrder"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuation"] forKeyPath:@"distanceBasedAttenuation"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedFiltering"] forKeyPath:@"distanceBasedFiltering"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedDelay"] forKeyPath:@"distanceBasedDelay"];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    [document setValue:[self valueForKeyPath:keyPath] forKeyPath:[NSString stringWithFormat:@"projectSettings.%@", keyPath]];
    
    if([keyPath isEqualToString:@"ambisonicsOrder"])
        [[AudioEngine sharedAudioEngine] setAmbisonicsOrder:ambisonicsOrder];
}

@end
