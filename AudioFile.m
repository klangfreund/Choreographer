//
//  AudioFile.m
//  Choreographer
//
//  Created by Philippe Kocher on 24.08.09.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "AudioFile.h"
#import "ProgressPanel.h"


@implementation AudioFile

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	NSLog(@"AudioFile awakeFromInsert, path: %@", [self valueForKey:@"filePath"]);
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	NSLog(@"AudioFile awakeFromFetch, path: %@", [self valueForKey:@"filePath"]);
	[self openAudioFile];
}

- (void)dealloc
{
	NSLog(@"AudioFile: dealloc");
	[super dealloc];
	[waveformImage dealloc];
}

- (BOOL)openAudioFile
{	
	OSStatus err;
	
	const char *path = [[self valueForKey:@"filePath"] cStringUsingEncoding:1];
	
	// make CFURLRef from path
	fileRef = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8 *)path, strlen(path), false);
	
	// open audio file
	err = AudioFileOpenURL(fileRef, fsRdPerm, 0, &audioFileID);
	if( err == noErr )
	{
		AudioStreamBasicDescription basicDescription;
		UInt32 propsize = sizeof(AudioStreamBasicDescription);
		
		err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propsize, &basicDescription);
		NSAssert1(!err,@"AudioFileGetProperty failed with error %i",err);
		
//				printf("FILE LOADED...\n");
//				printf("SampleRate %f\n",basicDescription.mSampleRate);
//				printf("FormatID %ld\n",basicDescription.mFormatID);
//				printf("FormatFlags %ld\n",basicDescription.mFormatFlags);
//				printf("BytesPerPacket %ld\n",basicDescription.mBytesPerPacket);
//				printf("FramesPerPacket %ld\n",basicDescription.mFramesPerPacket);
//				printf("BytesPerFrame %ld\n",basicDescription.mBytesPerFrame);
//				printf("ChannelsPerFrame %ld\n",basicDescription.mChannelsPerFrame);
		
		// check channels
		if(basicDescription.mChannelsPerFrame != 1)
		{
			NSAlert *alert = [NSAlert alertWithMessageText:@"Wrong number of channels"
											 defaultButton:@"Can't import"
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:[NSString stringWithFormat:@"%s is not a mono audio file", path]];
			
			// show alert in a modal dialog
			[alert runModal];
			return NO;
		}
		
		// bytes per packet
		bytesPerPacket = basicDescription.mBytesPerPacket;
		
		// sampleRate
		sampleRate = basicDescription.mSampleRate;
		
		// data paket count	
		UInt64 filePackets;						
		
		propsize = sizeof(UInt64);
		err = AudioFileGetProperty(audioFileID,
								   kAudioFilePropertyAudioDataPacketCount,
								   &propsize,
								   &filePackets);
		
		NSAssert1(!err, @"AudioFileGetProperty (packet count) failed with error %i", err);
		
		//printf("filePackets %ld\n",filePackets);
		
		// number of frames
		numOfFrames = filePackets * basicDescription.mFramesPerPacket;
		
		// duration
		duration = numOfFrames / basicDescription.mSampleRate * 1000;
		
		// [self calculateOverviewImage];
		return YES;
	}
	else
		return NO;
}

- (void) calculateOverviewImage
{
	progress = [[ProgressPanel sharedProgressPanel] addProgressWithTitle:[NSString stringWithFormat:@"Calculating overview for %@", [self valueForKey:@"filePath"]]];
	
	[NSThread detachNewThreadSelector:@selector(calculateOverviewImageThread)
							 toTarget:self
						   withObject:nil];

}

- (void)calculateOverviewImageThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int framesPerPixel = 50;
	NSUInteger dataLength = ceil(numOfFrames / framesPerPixel);
	
	char *buffer = malloc(dataLength * 2); // min and max values
	char min, max;
	
	int i,j;
	for (i=0;i<dataLength;i++)
	{
		[progress setProgressValue: (float)i / dataLength / 2];
		
		/*----------------------------------------------------------------------------------
		 AudioFileReadPackets - Read packets of audio data from the audio file. For all 
		 uncompressed formats, packet = frame. 
		 ioNumPackets less than requested indicates end of file.
		 
		 
		 inUseCache 			- true if it is desired to cache the data upon read, else false
		 outNumBytes 			- on output, the number of bytes actually returned
		 outPacketDescriptions 	- on output, an array of packet descriptions describing
		 the packets being returned. NULL may be passed for this
		 parameter. Nothing will be returned for linear pcm data.   
		 inStartingPacket 		- the packet index of the first packet desired to be returned
		 ioNumPackets 			- on input, the number of packets to read, on output, the number of
		 packets actually read.
		 outBuffer 				- outBuffer should be a pointer to user allocated memory of size: 
		 number of packets requested times file's maximum (or upper bound on)
		 packet size.
		 //----------------------------------------------------------------------------------*/
		
		UInt32 ioNumPackets = framesPerPixel;
		UInt32 outNumBytes = ioNumPackets * bytesPerPacket;
		SInt16 outBuffer[ioNumPackets];
						
		OSStatus err = AudioFileReadPackets(audioFileID,
											NO,
											&outNumBytes,
											NULL,
											i * ioNumPackets, 
											&ioNumPackets, 
											outBuffer);
		
		
		NSAssert1(!err, @"AudioFileReadPackets failed with error %i", err);
		
		min = max = outBuffer[0];

		for(j=1;j<ioNumPackets;j++)
		{
			char sample = rand() / RAND_MAX * 128; //outBuffer[j];
			min = sample < min ? sample : min;
			max = sample > max ? sample : max;
		}
		
		buffer[i] = min;
		buffer[i + dataLength] = max;
	}
	
	
//	overviewData = [[NSData alloc] initWithBytes:buffer length:dataLength * 2];
//	[self setOverviewData];
	
	float overviewHeight, overviewBaseline, overviewWidth;
	
	overviewWidth = dataLength;
	overviewHeight = 60;
	overviewBaseline = 30;

	[waveformImage release];
	waveformImage = [[NSImage alloc] initWithSize:NSMakeSize(overviewWidth, overviewHeight)];
	NSBezierPath *waveformPath = [NSBezierPath bezierPath];
		
		
	float stepsize = dataLength / overviewWidth / 2;
	float index;
	float y1, y2;
	
	for(i=0,index=stepsize;index<dataLength * 0.5;i++, index += stepsize)
	{
		[progress setProgressValue: 0.5 + (float)index / dataLength];

		y1 = y2 = 0;
		for(j=floor(index);j<index+stepsize;j++)
		{
			y1 += (float)buffer[j] / 128;
			y2 += (float)buffer[j + (int)(dataLength * 0.5)] / 128;
		}
		
		y1 /= ceil(stepsize);
		y1 *= overviewHeight * 0.5;
		y2 /= ceil(stepsize);
		y2 *= overviewHeight * 0.5;
		[waveformPath moveToPoint: NSMakePoint(i, overviewBaseline + y1)];
		[waveformPath lineToPoint: NSMakePoint(i, overviewBaseline - y1)];
	}
	
	[waveformImage lockFocus];
	[[NSColor colorWithDeviceWhite:1.0 alpha:0.] set];
	[NSBezierPath fillRect: NSMakeRect(0, 0, overviewWidth, overviewHeight)] ;
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[[NSColor blackColor] set];
	[waveformPath setLineWidth : 0.0];		
	[waveformPath stroke];
	[waveformImage unlockFocus];
	
	
	// ---
	//NSLog(@"....finished calculateOverviewImage");
	for(id audioItem in [self valueForKey:@"audioItems"])
	{
		if([[audioItem valueForKey:@"audioRegions"] count])
		{
			NSView *arrangerView = [[[NSDocumentController sharedDocumentController] currentDocument] valueForKey:@"arrangerView"];
			[arrangerView setNeedsDisplay:YES];		
			break;
		}
	}
	// ---
	
	[[ProgressPanel sharedProgressPanel] removeProgress:progress];

	[pool release];	
	free(buffer);
	
}

- (void)setOverviewData
{
	// the waveform data is now stored in the model
	// this action is excluded from the undo chain
	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] disableUndoRegistration];
	[self setValue:overviewData forKey:@"overview"];
	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] enableUndoRegistration];
	
}

@end
