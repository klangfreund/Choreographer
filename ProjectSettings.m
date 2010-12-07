//
//  ProjectSettings.m
//  Choreographer
//
//  Created by Philippe Kocher on 26.10.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "ProjectSettings.h"


@implementation ProjectSettings

- (id) init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (void)dealloc
{
	NSLog(@"ProjectSettings: dealloc");
	
	[projectSettingsDictionary release];	
	[super dealloc];
}


#pragma mark -
#pragma mark life cycle
// -----------------------------------------------------------

- (void)awakeFromInsert
{
	NSLog(@"ManagedProjectSettings: awake from insert");
	projectSettingsDictionary = [[ProjectSettingsDictionary alloc] initWithDefaults];
	[self archiveData];
}

- (void)awakeFromFetch
{
	NSLog(@"ManagedProjectSettings: awake from fetch");
	[self unarchiveData];
}

- (void)willSave
{
	NSLog(@"ManagedProjectSettings: will save");
	[self archiveData];
}

#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (void)archiveData
{ 
	NSMutableData *data;
	NSKeyedArchiver *archiver;
	
	data = [NSMutableData data];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:projectSettingsDictionary forKey:@"projectSettingsDictionary"];
	[archiver finishEncoding];
	
	[self setPrimitiveValue:data forKey:@"settingsData"];
	[archiver release];
}

- (void)unarchiveData
{
	NSMutableData *data;
	NSKeyedUnarchiver* unarchiver;
	
	[projectSettingsDictionary release];
	projectSettingsDictionary = nil;
	data = [self primitiveValueForKey:@"settingsData"];
	if(data)
	{
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		projectSettingsDictionary = [[unarchiver decodeObjectForKey:@"projectSettingsDictionary"] retain];
		[unarchiver finishDecoding];
		[unarchiver release];
	}	

}	


@end

#pragma mark -
#pragma mark -


@implementation ProjectSettingsDictionary

//- (id)init
//{
//	self = [super init];
//	if (self)
//	{
//		dictionary = [[NSMutableDictionary alloc] init];
//	}
//	return self;
//}
//
- (id)initWithDefaults
{
	self = [super init];
	if (self)
	{
		dictionary = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
							   
							   
							   // window
							   @"", @"projectWindowFrame",
							   [NSNumber numberWithFloat:180], @"poolViewWidth",
							   
							   
							   // arranger
							   [NSNumber numberWithInt:0], @"arrangerDisplayMode",
							   
							   [NSNumber numberWithInt:0], @"arrangerHorizontalGridMode",
							   [NSNumber numberWithInt:0], @"arrangerHorizontalGridAmount",
							   
							   [NSNumber numberWithInt:0], @"arrangerVerticalGridMode",
							   
							   [NSNumber numberWithInt:0], @"arrangerNudgeAmount",
							   
							   
							   // loop
							   [NSNumber numberWithBool:NO], @"loopMode",
							   [NSNumber numberWithInt:0], @"loopRegionStart",
							   [NSNumber numberWithInt:5000], @"loopRegionEnd",
							   
							   
							   // zoom
							   [NSNumber numberWithFloat:0.01], @"zoomFactorX",
							   [NSNumber numberWithFloat:1.], @"zoomFactorY",
							   
							   
							   // pool
							   [NSNumber numberWithBool:YES], @"poolDisplayed",
							   [NSNumber numberWithInt:0], @"poolDropOrder",
							   [NSNumber numberWithInt:0], @"poolSelectedTab",
							   
							   nil] retain];
	}
	return self;
}

- (void)dealloc
{
	NSLog(@"ProjectSettingsDictionary: dealloc");
	
	[dictionary release];	
	[super dealloc];
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    dictionary = [[coder decodeObjectForKey:@"dictionary"] retain];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:dictionary forKey:@"dictionary"];
}

	

#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (id)valueForKey:(NSString *)key
{
	return [dictionary valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
//	NSLog(@"ProjectSettingsDictionary: value %d for %@", value, key);

	NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
	[tempDictionary setValue:value forKey:key];
	
	[dictionary release];
	dictionary = [[tempDictionary copy] retain];

	// send notifications
	[[NSNotificationCenter defaultCenter] postNotificationName:@"projectSettingsDidChange" object:self];
}

@end
