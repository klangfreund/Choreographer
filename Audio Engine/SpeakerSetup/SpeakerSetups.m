//
//  SpeakerSetups.m
//  Choreographer
//
//  Created by Philippe Kocher on 06.10.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "SpeakerSetups.h"
#import "AudioEngine.h"


@implementation SpeakerChannel

@synthesize dbGain, solo, mute, position, hardwareDeviceOutputChannel;


- (id)init
{
	self = [super init];
	if(self)
	{
		dbGain = 0;
		position = [[SpatialPosition alloc] init];
		position.d = 1;
		hardwareDeviceOutputChannel = -1;
	}
	
	return self;
}

- (void)dealloc
{
	[self unregisterObserver:observer];
	
	[position release];
	[super dealloc];
}

- (void)registerObserver:(id)object
{
	if(object != observer) [self unregisterObserver:observer]; // only one single observer
	
	observer = [object retain];
	
	[self addObserver:observer forKeyPath:@"dbGain" options:0 context:nil];
	[self addObserver:observer forKeyPath:@"solo" options:0 context:nil];
	[self addObserver:observer forKeyPath:@"mute" options:0 context:nil];
	[self addObserver:observer forKeyPath:@"position.a" options:0 context:nil];
	[self addObserver:observer forKeyPath:@"position.e" options:0 context:nil];
	[self addObserver:observer forKeyPath:@"position.d" options:0 context:nil];
	[self addObserver:observer forKeyPath:@"hardwareDeviceOutputChannel" options:0 context:nil];
}

- (void)unregisterObserver:(id)object
{
	if(!object) return;
			
	[self removeObserver:observer forKeyPath:@"dbGain"];
	[self removeObserver:observer forKeyPath:@"solo"];
	[self removeObserver:observer forKeyPath:@"mute"];
	[self removeObserver:observer forKeyPath:@"position.a"];
	[self removeObserver:observer forKeyPath:@"position.e"];
	[self removeObserver:observer forKeyPath:@"position.d"];
	[self removeObserver:observer forKeyPath:@"hardwareDeviceOutputChannel"];

	[observer release];
	observer = nil;
}


#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (id)initWithCoder:(NSCoder *)coder
{
    dbGain = [coder decodeFloatForKey:@"dbGain"];
	position = [[coder decodeObjectForKey:@"position"] retain];
    hardwareDeviceOutputChannel = [coder decodeIntForKey:@"output"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeFloat:dbGain forKey:@"dbGain"];
    [coder encodeObject:position forKey:@"position"];
	[coder encodeInt:hardwareDeviceOutputChannel forKey:@"output"];
}

#pragma mark -
#pragma mark copy
// -----------------------------------------------------------

- (id)copyWithZone:(NSZone *)zone
{
	SpeakerChannel *copy = [[[SpeakerChannel alloc] init] autorelease];
	
	[copy setValue:[NSNumber numberWithFloat:dbGain] forKey:@"dbGain"];
	[copy setValue:[[position copy] retain] forKey:@"position"];
	[copy setValue:[NSNumber numberWithInt:hardwareDeviceOutputChannel] forKey:@"hardwareDeviceOutputChannel"];
	
	return copy;
}
		
@end

#pragma mark -
#pragma mark -

@implementation SpeakerSetupPreset

- (id)init
{
	self = [super init];
	if(self)
	{
		speakerChannels = [[NSMutableArray alloc] init];
		dirty = NO;
	}
	return self;
}

- (void) dealloc
{
	[speakerChannels release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"Preset: %@ observe key path %@", self, keyPath);
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];

	// updateEngine
	if([keyPath isEqualToString:@"hardwareDeviceOutputChannel"])
	{
		[self updateEngineRoutingForChannel:object];
	}
	else
	{
		[self updateEngineForChannel:object];
	}
}

- (void)synchronizeWith:(SpeakerSetupPreset *)preset
{
	[self setName:[preset valueForKey:@"name"]];

	NSMutableArray *tempChannels = [[[NSMutableArray alloc] init] autorelease];
	for(SpeakerChannel *channel in [preset valueForKey:@"speakerChannels"])
	{
		SpeakerChannel *tempChannel = [channel copy];
		[tempChannels addObject:tempChannel];
		[tempChannel registerObserver:self];
	}
	
	[self setValue:tempChannels forKey:@"speakerChannels"];

}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)newSpeakerChannel
{
	[self addSpeakerChannel:[[[SpeakerChannel alloc] init] autorelease]];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];

	// "updateEngine" deletes and rewrites everything
	// TODO: optimize
	[self updateEngine];
}

- (void)addSpeakerChannel:(SpeakerChannel *)channel
{
	[speakerChannels addObject:channel];
	[channel registerObserver:self];
	// no need to set dirty flag here
}

- (void)removeSpeakerChannelAtIndex:(NSUInteger)i
{
	[speakerChannels removeObjectAtIndex:i];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];

	// "updateEngine" deletes and rewrites everything
	// TODO: optimize
	[self updateEngine];
}


#pragma mark -
#pragma mark update engine
// -----------------------------------------------------------

- (void)updateEngine
{
	NSLog(@"update engine....");
	
	// remove all speaker channels in order to build a new speaker setup from scatch
	[[AudioEngine sharedAudioEngine] removeAllSpeakerChannels];
	
	// add the speaker channels
	for(SpeakerChannel *channel in speakerChannels)
	{
		[[AudioEngine sharedAudioEngine] addSpeakerChannel:channel atIndex:[speakerChannels indexOfObject:channel]];
	}

	// finally: validate the new setup (ie. rebuild the audio buffers)
	[[AudioEngine sharedAudioEngine] validateSpeakerSetup];
}

- (void)updateEngineForChannel:(SpeakerChannel *)channel
{
	[[AudioEngine sharedAudioEngine] updateParametersForChannel:channel atIndex:[speakerChannels indexOfObject:channel]];
}

- (void)updateEngineRoutingForChannel:(SpeakerChannel *)channel
{
	[[AudioEngine sharedAudioEngine] updateRoutingForChannel:channel atIndex:[speakerChannels indexOfObject:channel]];
}



#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (void)setName:(NSString *)string
{
	[name release];
	name = [string retain];
	
	if(dirty)
		[self setValue:[NSString stringWithFormat:@"- %@",name] forKey:@"displayedName"];
	else
		[self setValue:[NSString stringWithString:name] forKey:@"displayedName"];
}

- (void)setDirty:(BOOL)val
{
	NSLog(@"Preset: %@ setDirty %i", self, val);

	dirty = val;

	if(dirty)
		[self setValue:[NSString stringWithFormat:@"- %@",name] forKey:@"displayedName"];
	else
		[self setValue:[NSString stringWithString:name] forKey:@"displayedName"];
}

- (NSUInteger)countSpeakerChannels
{
	return [speakerChannels count];
}

- (NSArray *)speakerChannels
{
	return [NSArray arrayWithArray:speakerChannels];
}

- (SpeakerChannel *)speakerChannelAtIndex:(NSUInteger)i
{
	return [speakerChannels objectAtIndex:i];
}

#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (id)initWithCoder:(NSCoder *)coder
{
    name = [[coder decodeObjectForKey:@"name"] retain];
	[self setValue:[NSString stringWithString:name] forKey:@"displayedName"];
    speakerChannels = [[coder decodeObjectForKey:@"speakerChannels"] retain];
	
	for(SpeakerChannel *channel in speakerChannels)
	{
		[channel registerObserver:self];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:name forKey:@"name"];
    [coder encodeObject:speakerChannels forKey:@"speakerChannels"];
}

#pragma mark -
#pragma mark copy
// -----------------------------------------------------------

- (id)copyWithZone:(NSZone *)zone
{
	SpeakerSetupPreset *copy = [[[SpeakerSetupPreset alloc] init] autorelease];
	[copy setValue:[name copy] forKey:@"name"];
	[copy setValue:[displayedName copy] forKey:@"displayedName"];
	
	for(SpeakerChannel *channel in speakerChannels)
	{
		SpeakerChannel *channelCopy = [channel copy];
		[copy addSpeakerChannel:channelCopy];
	}
	
	return copy;
}

@end

#pragma mark -
#pragma mark -

@implementation SpeakerSetups

- (id)init
{
	self = [super init];
	if(self)
	{
	}
	
	return self;
}

- (void) dealloc
{
	[presets release];
	[storedPresets release];
	[super dealloc];
}


#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (void)archiveData
{ 
	NSLog(@"archive speaker setups");

	// synchronize with stored presets (only those presets that are not dirty)
	int i;
	for(i=0;i<[presets count];i++)
	{
		if(![[[presets objectAtIndex:i] valueForKey:@"dirty"] boolValue])
			[storedPresets replaceObjectAtIndex:i withObject:[[presets objectAtIndex:i] copy]];
	}
	
	NSMutableData *data;
	NSKeyedArchiver *archiver;
	
	data = [NSMutableData data];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:storedPresets forKey:@"presets"];
	[archiver encodeInt:selectedIndex forKey:@"selectedIndex"];
	[archiver finishEncoding];
	
	[[AudioEngine sharedAudioEngine] setPersistentSetting:data forKey:@"speakerSetups"];

	[archiver release];
}

- (void)unarchiveData
{
	NSLog(@"unarchive speaker setups");

 	NSMutableData *data;
	NSKeyedUnarchiver* unarchiver;
	
	[presets release];
	presets = nil;

	data = [[AudioEngine sharedAudioEngine] persistentSettingForKey:@"speakerSetups"];

	if(data)
	{
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		NSMutableArray *tempPresets = [[unarchiver decodeObjectForKey:@"presets"] retain];
		NSUInteger index = [unarchiver decodeIntForKey:@"selectedIndex"];
		[unarchiver finishDecoding];
		[unarchiver release];
		
//		[self setValue:tempPresets forKey:@"presets"];
//		[self setValue:[NSNumber numberWithUnsignedInt:index] forKey:@"selectedIndex"];
		presets = tempPresets;
		selectedIndex = index;
	}
	
	if(!presets)
	{
		// "factory presets"
		// ------------------------------------
		
		NSMutableArray *tempPresets = [[[NSMutableArray alloc] init] autorelease];
		
		SpeakerSetupPreset *setup;
		SpeakerChannel *channel;
		

		setup = [[[SpeakerSetupPreset alloc] init] autorelease];
		[tempPresets addObject:setup];
		[setup setValue:@"Quadrophonic" forKey:@"name"];
		[setup setValue:@"Quadrophonic" forKey:@"displayedName"];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithInt:-45] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:0] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithInt:45] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithInt:135] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:2] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithInt:-135] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:3] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		
		
		setup = [[[SpeakerSetupPreset alloc] init] autorelease];
		[tempPresets addObject:setup];
		[setup setValue:@"Eight Speakers" forKey:@"name"];
		[setup setValue:@"Eight Speakers" forKey:@"displayedName"];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithFloat:-22.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:0] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithFloat:22.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithFloat:67.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:2] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithFloat:105.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:3] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithFloat:157.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:4] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithFloat:-157.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithInt:5] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithFloat:-105.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:6] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		channel = [[[SpeakerChannel alloc] init] autorelease];
		[channel setValue:[NSNumber numberWithInt:1] forKeyPath:@"position.d"];
		[channel setValue:[NSNumber numberWithFloat:-67.5] forKeyPath:@"position.a"];
		[channel setValue:[NSNumber numberWithInt:7] forKeyPath:@"hardwareDeviceOutputChannel"];
		[setup addSpeakerChannel:channel];
		
		[self setValue:[NSNumber numberWithUnsignedInt:0] forKey:@"selectedIndex"];
		[self setValue:tempPresets forKey:@"presets"];
		[self archiveData];
	}
	
	[self setValue:[self copyPreset:presets] forKey:@"storedPresets"];


}	


#pragma mark -
#pragma mark XML import / export 
// -----------------------------------------------------------

#define speakerSetupsNodeName @"speakerSetups"
#define setupNodeName @"setup"
#define channelNodeName @"channel"
#define gainNodeName @"gain"
#define positionNodeName @"position"
#define hardwareDeviceOutputChannelNodeName @"output"

- (void)exportDataAsXML:(NSURL *)url
{
	NSString *filename = [NSString stringWithFormat:@"%@.xml", [[url URLByDeletingPathExtension] path]];
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:speakerSetupsNodeName];
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	for(SpeakerSetupPreset *setup in presets)
	{
		NSXMLElement* setupNode = [NSXMLElement elementWithName:setupNodeName];
		[root addChild:setupNode];
		[setupNode addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[setup valueForKey:@"name"]]];
		
		int i = 1;
		for(SpeakerChannel *channel in [setup speakerChannels])
		{
			NSXMLElement* channelNode = [NSXMLElement elementWithName:channelNodeName];
			[setupNode addChild:channelNode];
			[channelNode addAttribute:[NSXMLNode attributeWithName:@"index" stringValue:[NSString stringWithFormat:@"%i", i++]]];
			
			NSXMLElement* gainNode = [NSXMLElement elementWithName:gainNodeName];
			[gainNode addAttribute:[NSXMLNode attributeWithName:@"unit" stringValue:@"db"]];
			[gainNode setStringValue:[[channel valueForKey:@"dbGain"] stringValue]];
			[channelNode addChild:gainNode];
			
			NSXMLElement* positionNode = [NSXMLElement elementWithName:positionNodeName];
			[positionNode addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"xyz"]];
			[positionNode setStringValue:[NSString stringWithFormat:@"%f %f %f",
										  [[channel valueForKeyPath:@"position.x"] floatValue],
										  [[channel valueForKeyPath:@"position.y"] floatValue],
										  [[channel valueForKeyPath:@"position.z"] floatValue]]];
			[channelNode addChild:positionNode];
			
			[channelNode addChild:[NSXMLNode elementWithName:hardwareDeviceOutputChannelNodeName stringValue:[[channel valueForKeyPath:@"hardwareDeviceOutputChannel"] stringValue]]];
		}
	}

	
    NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![xmlData writeToFile:filename atomically:YES])
	{
        NSBeep();
		NSLog(@"failed saving the XML file");
    }
	
}

- (void)importXMLData:(NSArray *)filenames
{}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)addPreset:(SpeakerSetupPreset *)preset
{
	[preset setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];

	[presets insertObject:preset atIndex:selectedIndex + 1];
	[storedPresets insertObject:[preset copy] atIndex:selectedIndex + 1];
	[self setValue:[NSNumber numberWithUnsignedInt:selectedIndex + 1] forKey:@"selectedIndex"];
	
	[self setValue:presets forKey:@"presets"];
	[self archiveData];
}

- (void)deleteSelectedPreset;
{
	[presets removeObjectAtIndex:selectedIndex];
	[storedPresets removeObjectAtIndex:selectedIndex];

	if(selectedIndex > 0)
		[self setValue:[NSNumber numberWithUnsignedInt:selectedIndex - 1] forKey:@"selectedIndex"];
	else
		[self setValue:[NSNumber numberWithUnsignedInt:0] forKey:@"selectedIndex"];


	[self setValue:presets forKey:@"presets"];
	[self archiveData];
}

- (void)saveSelectedPreset
{
	SpeakerSetupPreset *selectedPreset = [self selectedPreset];
	[selectedPreset setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
	[self archiveData];
}

- (void)selectedPresetRevertToSaved
{
//	SpeakerSetupPreset *selectedPreset = [self selectedPreset];

	// find the preset in the stored presets and replace it in presets
	[[presets objectAtIndex:selectedIndex] synchronizeWith:[storedPresets objectAtIndex:selectedIndex]];
	[self setValue:presets forKey:@"presets"];
	[[self selectedPreset] setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
}

- (void)saveAllPresets
{
	for(SpeakerSetupPreset *preset in presets)
	{
		[preset setDirty:NO];
	}
	[self archiveData];
}

- (void)discardAllChanges
{
	[self archiveData];
}



#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (void)setSelectedIndex:(NSUInteger)index
{
	// the selected setup preset has been changed
	// - update the engine to activate the selected setup
	// - archive data to permanently store the selected index
	
	selectedIndex = index;
	[[self selectedPreset] updateEngine];
	[self archiveData];
}

- (SpeakerSetupPreset *)selectedPreset
{
	if(selectedIndex >= [presets count]) return nil;
	
	return [presets objectAtIndex:selectedIndex];
}

- (BOOL)dirtyPresets
{
	for(SpeakerSetupPreset *preset in presets)
	{
		if([[preset valueForKey:@"dirty"] boolValue]) return YES;
	}
	
	return NO;
	
}


#pragma mark -
#pragma mark misc
// -----------------------------------------------------------
- (NSMutableArray *)copyPreset:(NSArray *)presetArray
{
	NSMutableArray *arrayCopy = [[[NSMutableArray alloc] init] autorelease];
	
	for(SpeakerSetupPreset *preset in presetArray)
	{
		[arrayCopy addObject:[preset copy]];
	}
	
	return arrayCopy;
}


@end
