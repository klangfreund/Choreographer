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
    	[self addObserver:self forKeyPath:@"distanceBasedAttenuationCentreZoneSize" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedAttenuationCentreDB" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedAttenuationCentreExponent" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedAttenuationMode" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedAttenuationDbFalloff" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedAttenuationExponent" options:0 context:nil];

    	[self addObserver:self forKeyPath:@"distanceBasedFiltering" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedFilteringHalfCutoffUnit" options:0 context:nil];
        
    	[self addObserver:self forKeyPath:@"distanceBasedDelay" options:0 context:nil];
    	[self addObserver:self forKeyPath:@"distanceBasedDelayMilisecondsPerUnit" options:0 context:nil];

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
    document = [[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument"];

    [NSApp beginSheet: [self window]
       modalForWindow: [document windowForSheet]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];

    [self setValue:[document valueForKeyPath:@"projectSettings.ambisonicsOrder"] forKeyPath:@"ambisonicsOrder"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuation"] forKeyPath:@"distanceBasedAttenuation"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationCentreZoneSize"] forKeyPath:@"distanceBasedAttenuationCentreZoneSize"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationCentreDB"] forKeyPath:@"distanceBasedAttenuationCentreDB"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationCentreExponent"] forKeyPath:@"distanceBasedAttenuationCentreExponent"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationMode"] forKeyPath:@"distanceBasedAttenuationMode"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationDbFalloff"] forKeyPath:@"distanceBasedAttenuationDbFalloff"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationExponent"] forKeyPath:@"distanceBasedAttenuationExponent"];

    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedFiltering"] forKeyPath:@"distanceBasedFiltering"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedFilteringHalfCutoffUnit"] forKeyPath:@"distanceBasedFilteringHalfCutoffUnit"];

    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedDelay"] forKeyPath:@"distanceBasedDelay"];
    [self setValue:[document valueForKeyPath:@"projectSettings.distanceBasedDelayMilisecondsPerUnit"] forKeyPath:@"distanceBasedDelayMilisecondsPerUnit"];
}

- (IBAction)closeWindow:(id)sender
{
    [NSApp endSheet:[self window]];
    [[self window] orderOut:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    // update document preferences
    [document setValue:[self valueForKeyPath:keyPath] forKeyPath:[NSString stringWithFormat:@"projectSettings.%@", keyPath]];
    
    // update audio engine
    if([keyPath isEqualToString:@"ambisonicsOrder"])
        [[AudioEngine sharedAudioEngine] setAmbisonicsOrder:ambisonicsOrder];
    else if([keyPath isEqualToString:@"distanceBasedAttenuation"])
        [attenuationCurveView setEnabled:distanceBasedAttenuation];
    else if([keyPath isEqualToString:@"distanceBasedDelay"] || [keyPath isEqualToString:@"distanceBasedDelayMilisecondsPerUnit"])
    {
        double time = distanceBasedDelay ? distanceBasedDelayMilisecondsPerUnit : 0;
        [[AudioEngine sharedAudioEngine] setDistanceBasedDelay:time];
    }
    else if([keyPath isEqualToString:@"distanceBasedFiltering"] || [keyPath isEqualToString:@"distanceBasedFilteringHalfCutoffUnit"])
    {
        double halfCutoff = distanceBasedFiltering ? distanceBasedFilteringHalfCutoffUnit : 0;
        [[AudioEngine sharedAudioEngine] setDistanceBasedFiltering:halfCutoff];
    }
    
    NSRange range = [keyPath rangeOfString:@"distanceBasedAttenuation"];
    if(range.location != NSNotFound)
    {
        int mode = distanceBasedAttenuation ? distanceBasedAttenuationMode + 1 : 0;
        [[AudioEngine sharedAudioEngine] setDistanceBasedAttenuation:mode
                                                      centreZoneSize:distanceBasedAttenuationCentreZoneSize
                                                      centreExponent:distanceBasedAttenuationCentreExponent
                                                   centreAttenuation:distanceBasedAttenuationCentreDB
                                                    dBFalloffPerUnit:distanceBasedAttenuationDbFalloff
                                                 attenuationExponent:distanceBasedAttenuationExponent];

        [attenuationCurveView setNeedsDisplay:YES];
    }
}

@end


@implementation MilisecondsPerUnitToDistanceFactor

+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return YES; }
- (id)transformedValue:(id)value
{
    return (value == nil) ? nil : [NSNumber numberWithDouble:[value doubleValue] * 3.4];
}
- (id)reverseTransformedValue:(id)value
{
    return (value == nil) ? nil : [NSNumber numberWithDouble:[value doubleValue] / 3.4];
}

@end 