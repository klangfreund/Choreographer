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
