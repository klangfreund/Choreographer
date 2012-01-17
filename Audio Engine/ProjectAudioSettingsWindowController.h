//
//  ProjectAudioSettingsWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 16.01.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProjectAudioSettingsWindowController : NSWindowController
{
//    id audioEngine;
    id document;
    
    float ambisonicsOrder;
    
    BOOL distanceBasedAttenuation;
    BOOL distanceBasedFiltering;
    BOOL distanceBasedDelay;
}
@end
