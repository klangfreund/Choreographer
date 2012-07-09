//
//  BounceToDiskController.m
//  Choreographer
//
//  Created by Philippe Kocher on 04.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "BounceToDiskController.h"
#import "AudioEngine.h"


@implementation BounceToDiskController

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		bounceStart = 10;
		bounceEnd = 20000;
	}
	return self;
}


- (void)bounceToDisk:(id)doc
{
	document = doc;

	[[AudioEngine sharedAudioEngine] stopAudio];

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"wav",nil]];
	[savePanel setNameFieldStringValue:[[document displayName] stringByDeletingPathExtension]];
	[savePanel setPrompt:@"Bounce..."];
	[savePanel setExtensionHidden:YES];
	
	// accessory view (project sample rate)
	[self setValue:[NSNumber numberWithInt:bounceMode] forKey:@"bounceMode"];
	[savePanel setAccessoryView:bouncePanelAccessoryView];
	
	[savePanel beginSheetModalForWindow:[document windowForSheet] completionHandler:^(NSInteger result)
    {
		 if (result == NSOKButton)
		 {
			 [savePanel orderOut:self];
			 [[AudioEngine sharedAudioEngine] bounceToDisk:[savePanel URL] start:bounceStart end:bounceEnd];
		 }
	 }];
}


- (void)setBounceMode:(int)val
{
	bounceMode = val;
	
	switch(val)
	{
		case 0:
			[self setBounceStart:0];
			[self setBounceEnd:[[document valueForKeyPath:@"arrangerView.arrangerContentEnd"] integerValue]];
			break;
		case 1:
			[self setBounceStart:[[document valueForKeyPath:@"projectSettings.loopRegionStart"] integerValue]];
			[self setBounceEnd:[[document valueForKeyPath:@"projectSettings.loopRegionEnd"] integerValue]];
			break;
		case 2:
			break;
	}
}

- (void)setBounceStart:(NSInteger)val
{
	bounceStart = val;
	
	if((bounceMode == 0 && bounceStart != 0)
	   || (bounceMode == 1 && bounceStart != [[document valueForKeyPath:@"projectSettings.loopRegionStart"] integerValue]))
		[self setBounceMode:2];
}

- (void)setBounceEnd:(NSInteger)val
{
	bounceEnd = val;

	if((bounceMode == 0 && bounceEnd != [[document valueForKeyPath:@"arrangerView.arrangerContentEnd"] unsignedIntValue])
	   || (bounceMode == 1 && bounceEnd != [[document valueForKeyPath:@"projectSettings.loopRegionEnd"] integerValue]))
		[self setBounceMode:2];
}

@end
