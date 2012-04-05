//
//  theDictionary.m
//  Choreographer
//
//  Created by Philippe Kocher on 10.01.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import "ProjectSettings.h"

@implementation ProjectSettings


- (id)initWithDefaults
{    
    self = [super init];
    if (self)
    {
        theDictionary = [[NSMutableDictionary alloc] init];
        
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"arrangerDisplayMode"];       
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"arrangerNudgeAmount"];       
        [theDictionary setValue:[NSNumber numberWithDouble:0.0] forKey:@"arrangerScrollOriginX"];       
        [theDictionary setValue:[NSNumber numberWithDouble:0.0] forKey:@"arrangerScrollOriginY"];       
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"arrangerXGridAmount"];       
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"arrangerXGridLines"];       
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"arrangerYGridLines"];       
        [theDictionary setValue:[NSNumber numberWithDouble:0.01] forKey:@"arrangerZoomFactorX"];       
        [theDictionary setValue:[NSNumber numberWithDouble:1.0] forKey:@"arrangerZoomFactorY"];       
        
        [theDictionary setValue:[NSNumber numberWithBool:NO] forKey:@"loopMode"];       
        [theDictionary setValue:[NSNumber numberWithUnsignedLong:0.0] forKey:@"loopRegionStart"];       
        [theDictionary setValue:[NSNumber numberWithUnsignedLong:5000] forKey:@"loopRegionEnd"];       
        [theDictionary setValue:[NSNumber numberWithBool:YES] forKey:@"poolDisplayed"];       
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"poolDropOrder"];       
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"poolSelectedTab"];       
        [theDictionary setValue:[NSNumber numberWithFloat:200] forKey:@"poolViewWidth"];       
        [theDictionary setValue:[NSNumber numberWithDouble:0.0] forKey:@"projectMasterVolume"];
        [theDictionary setValue:nil forKey:@"projectWindowFrame"];
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"projectSampleRate"];
        
        // project audio settings
        [theDictionary setValue:[NSNumber numberWithFloat:3.0] forKey:@"ambisonicsOrder"];       
        [theDictionary setValue:[NSNumber numberWithBool:YES] forKey:@"distanceBasedAttenuation"];
        [theDictionary setValue:[NSNumber numberWithFloat:0.1] forKey:@"distanceBasedAttenuationCentreZoneSize"];
        [theDictionary setValue:[NSNumber numberWithFloat:-6] forKey:@"distanceBasedAttenuationCentreDB"];
        [theDictionary setValue:[NSNumber numberWithFloat:0.2] forKey:@"distanceBasedAttenuationCentreExponent"];
        [theDictionary setValue:[NSNumber numberWithInt:0] forKey:@"distanceBasedAttenuationMode"];
        [theDictionary setValue:[NSNumber numberWithFloat:-3] forKey:@"distanceBasedAttenuationDbFalloff"];
        [theDictionary setValue:[NSNumber numberWithFloat:1] forKey:@"distanceBasedAttenuationExponent"];
        
        [theDictionary setValue:[NSNumber numberWithBool:NO] forKey:@"distanceBasedFiltering"];   
        [theDictionary setValue:[NSNumber numberWithDouble:0.2] forKey:@"distanceBasedFilteringHalfCutoffUnit"]; 

        [theDictionary setValue:[NSNumber numberWithBool:NO] forKey:@"distanceBasedDelay"]; 
        [theDictionary setValue:[NSNumber numberWithDouble:10] forKey:@"distanceBasedDelayMilisecondsPerUnit"]; 
    }
    return self;
}

- (void)dealloc
{
    [theDictionary release];
    [super dealloc];
}


- (void)setValue:(id)value forKey:(NSString *)key
{
    [theDictionary setObject:value forKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"projectSettingsDidChange" object:self];
}

- (id)valueForKey:(NSString *)key
{
    return [theDictionary valueForKey:key];
}

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    [theDictionary addObserver:anObserver forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath
{
    [theDictionary removeObserver:anObserver forKeyPath:keyPath];
}


#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (id)initWithCoder:(NSCoder *)coder
{
    theDictionary = [[coder decodeObjectForKey:@"data"] retain];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:theDictionary forKey:@"data"];
}

@end
