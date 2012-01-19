//
//  ProjectAudioSettingsWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 16.01.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AttenuationCurveView.h"

@interface ProjectAudioSettingsWindowController : NSWindowController
{
//    id audioEngine;
    id document;
    
    IBOutlet AttenuationCurveView *attenuationCurveView;
    
    float ambisonicsOrder;
    
    BOOL distanceBasedAttenuation;
    float distanceBasedAttenuationCentreZoneSize;
    float distanceBasedAttenuationCentreDB;
    float distanceBasedAttenuationCentreExponent;
    int   distanceBasedAttenuationMode;
    float distanceBasedAttenuationDbFalloff;
    float distanceBasedAttenuationExponent;
    BOOL distanceBasedFiltering;
    BOOL distanceBasedDelay;
}

- (IBAction)closeWindow:(id)sender;

@end
