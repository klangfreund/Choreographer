/*
 *  AudioRegionMixer.cpp
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 100425.
 *  Copyright 2010. All rights reserved.
 *
 */

//#include "../../core/juce_StandardHeader.h"

//BEGIN_JUCE_NAMESPACE

#include "AudioRegionMixer.h"

//==============================================================================
AudioRegionMixer::AudioRegionMixer()
    : tempBuffer (2,0),
	  nextPlayPosition (0),
      totalLength (0),
      samplesPerBlockExpected (512),
      sampleRate (44100.0)
{
	DBG(T("AudioRegionMixer: constructor called."));
}

AudioRegionMixer::~AudioRegionMixer()
{
	DBG(T("AudioRegionMixer: destructor called."));
	removeAllRegions();
}

bool AudioRegionMixer::addRegion (const int regionID,
								  const int startPosition, 
								  const int endPosition,
								  const int startPositionOfAudioFileInTimeline,
								  String absolutePathToAudioFile,
								  double sampleRateOfTheAudioDevice)
{
	DBG(T("AudioRegionMixer: addRegion called."));
	
	int index; // just here because findRegion needs it
	bool foundTheRegion = findRegion(regionID, index);
	if (foundTheRegion)
	{
		DBG(T("AudioRegionMixer: Didn't add the region because its regionID already exists."))
		return false;
	}
	
	// --- begin{audio file stuff} ---
	 File audioFile(absolutePathToAudioFile);
	
	 // get a format manager and set it up with the basic types (wav and aiff).
	 AudioFormatManager audioFormatManager;
	 audioFormatManager.registerBasicFormats();
		// Currently, this registers the WAV and AIFF formats.
	
	 AudioFormatReader* audioFormatReader = audioFormatManager.createReaderFor (audioFile);
	 // This audioFormatReader will be deleted when the audioFormatReaderSource will
	 // be deleted
	// --- end{audio file stuff} ---
	
	// if the previous lines of code weren't successful
	if (audioFormatReader == 0)
	{
		DBG(T("AudioRegionMixer: Didn't add region because the audio file couldn't be read."))
		delete audioFormatReader;
		return false;
	}
	// check if this input set is invalid
	else if (startPosition >= endPosition
			 || startPosition < startPositionOfAudioFileInTimeline
			 || endPosition - startPositionOfAudioFileInTimeline > audioFormatReader->lengthInSamples)
	{
		DBG(T("AudioRegionMixer: Didn't add region because the set (startPosition, endPosition, startPositionOfAudioFileInTimeline, file length) doesn't make sense."))
		return false;
	}
	// add the region
	else
	{
		// generate a new AudioRegion element
		AudioRegion* audioRegionToAdd = new AudioRegion();
		audioRegionToAdd->regionID = regionID;
		audioRegionToAdd->startPosition = startPosition;
		audioRegionToAdd->endPosition = endPosition;
		audioRegionToAdd->startPositionOfAudioFileInTimeline = startPositionOfAudioFileInTimeline;		
		AudioSourceAmbipanning *audioSourceAmbipanning = new AudioSourceAmbipanning (audioFormatReader,
																					 sampleRateOfTheAudioDevice);		
		audioRegionToAdd->audioSourceAmbipanning = audioSourceAmbipanning;
		
		// add the region
		regions.add(audioRegionToAdd);
		
		// prepare it to be played
		audioRegionToAdd->audioSourceAmbipanning->prepareToPlay(samplesPerBlockExpected, sampleRate);
		
		// update totalLength, if needed
		if (totalLength < endPosition ) {
			totalLength = endPosition;
		}
		
		return true;
	}
		
	
}

bool AudioRegionMixer::modifyRegion (const int regionID, const int newStartPosition, const int newEndPosition,
				   const int newStartPositionOfAudioFileInTimeline)
{
	DBG(T("AudioRegionMixer: modifyRegion called."));
	
	int index;
	bool foundTheRegion = findRegion(regionID, index);
	
	if (foundTheRegion)
	{
		AudioRegion* audioRegionToModify = (AudioRegion*)regions[index];
		
		// check if this input set is invalid
		if (newStartPosition >= newEndPosition
				 || newStartPosition < newStartPositionOfAudioFileInTimeline
				 || newEndPosition - newStartPositionOfAudioFileInTimeline 
					> audioRegionToModify->audioSourceAmbipanning->getTotalLength())
		{
			DBG(T("AudioRegionMixer: Didn't modify region because the set (newStartPosition, endPosition, startPositionOfAudioFileInTimeline, file length) doesn't make sense."))
			return false;
		}
		
		
		audioRegionToModify->startPosition = newStartPosition;
		audioRegionToModify->endPosition = newEndPosition;
		audioRegionToModify->startPositionOfAudioFileInTimeline = newStartPositionOfAudioFileInTimeline;
		
		return true;
	}
	else
	{
		DBG(T("AudioRegionMixer: Can't remove the region because the specified regionID can't be found."))
		return false;
	}
}

bool AudioRegionMixer::removeRegion (const int regionID)
{
	DBG(T("AudioRegionMixer: removeRegion called."));
	
	int index;
	bool foundTheRegion = findRegion(regionID, index);
	
	if (foundTheRegion)
	{
		AudioRegion* audioRegionToDelete = (AudioRegion*)regions[index];
		delete audioRegionToDelete->audioSourceAmbipanning;
		delete audioRegionToDelete;
		
		regions.remove(index);
		
		return true;
	}
	else
	{
		DBG(T("AudioRegionMixer: Can't remove the region because the specified regionID can't be found."))
		return false;
	}
	
}

void AudioRegionMixer::removeAllRegions ()
{
	DBG(T("AudioRegionMixer: removeAllRegions called."));
	
	const ScopedLock sl (lock);
	
	// Deallocate memory...
	for (int i = 0; i < regions.size(); i++)
	{
		AudioRegion* audioRegionToDelete = (AudioRegion*)regions[i];
		delete audioRegionToDelete->audioSourceAmbipanning;
		delete audioRegionToDelete;
	}
	
	// ... and remove the pointers.
	regions.clear();
}

bool AudioRegionMixer::setGainEnvelopeForRegion (const int regionID, Array<void*> gainEnvelope)
{
	int index;
	bool foundTheRegion = findRegion(regionID, index);
	
	if (foundTheRegion)
	{
		if (gainEnvelope.size() != 0)
		{
			AudioRegion* audioRegionToModify = (AudioRegion*)regions[index];
			
			// if we are dealing with a non constant envelope
			if (gainEnvelope.size() > 1)
			{
				// to make getNextAudioBlock(..) in AudioSourceGainEnvelope work, the first point
				// in the envelope must be at position 0 and the last point must be at a position
				// after the last sample of this region.
				// If this is not the case, this code adds additional points with the same value
				// as the closest point.
				gainEnvelope.sort(audioEnvelopePointComparator);
				
				AudioEnvelopePoint* firstGainPoint = (AudioEnvelopePoint*)gainEnvelope[0];
				if (firstGainPoint->getPosition() > 0)
				{
					AudioEnvelopePoint* newFirstGainPoint = new AudioEnvelopePoint(0, firstGainPoint->getValue());
					gainEnvelope.addSorted(audioEnvelopePointComparator, newFirstGainPoint);
				}
				AudioEnvelopePoint* lastGainPoint = (AudioEnvelopePoint*)gainEnvelope[gainEnvelope.size()-1];
				int lengthOfThisRegion = audioRegionToModify->endPosition - audioRegionToModify->startPosition;
				if (lastGainPoint->getPosition() < lengthOfThisRegion )
				{
					AudioEnvelopePoint* newLastGainPoint = new AudioEnvelopePoint(lengthOfThisRegion,
																				  lastGainPoint->getValue());
					gainEnvelope.addSorted(audioEnvelopePointComparator, newLastGainPoint);
				}
				
				//temp: for debugging only
				// firstGainPoint = (AudioEnvelopePoint*)gainEnvelope[0];
				// DBG(String(firstGainPoint->getPosition()) + T(", ") + String(firstGainPoint->getValue()));
			}

			audioRegionToModify->audioSourceAmbipanning->setGainEnvelope (gainEnvelope);
			return true;
		}
		else
		{
			DBG(T("AudioRegionMixer: Can't attach a gain envelope to the region because the specified gainEnvelope is empty."))
			return false;
		}

	}
	else
	{
		DBG(T("AudioRegionMixer: Can't attach a gain envelope to the region because the specified regionID can't be found."))
		return false;
	}
}

void AudioRegionMixer::setSpeakerPositions (Array<void*> positionOfSpeaker)
{
	const ScopedLock sl (lock); // without this scope lock, getNextAudioBlock(..) of
	  // AudioSourceAmbipanning might wanna set array elements outside of the size of
	  // these arrays
	AudioSourceAmbipanning::setPositionOfSpeakers (positionOfSpeaker);
	AudioSourceAmbipanning::setNumberOfSpeakers (positionOfSpeaker.size());	
	// inform all regions about the change
	for (int i = 0; i < regions.size() && positionOfSpeaker.size(); i++)
	{
		((AudioRegion*)regions[i])->audioSourceAmbipanning->reallocateMemoryForTheArrays();
	}
}

bool AudioRegionMixer::setSpacialEnvelopeForRegion (const int& regionID, Array<SpacialEnvelopePoint> spacialEnvelope)
{
	int index;
	bool foundTheRegion = findRegion(regionID, index);
	
	if (foundTheRegion)
	{
		if (spacialEnvelope.size() != 0)
		{
			AudioRegion* audioRegionToModify = (AudioRegion*)regions[index];
			
			// if we are dealing with a non constant envelope
			if (spacialEnvelope.size() > 1)
			{
				// to make getNextAudioBlock(..) in AudioSourceAmbipanning work, the first point
				// in the envelope must be at position 0 and the last point must be at a position
				// after the last sample of this region.
				// If this is not the case, this code adds additional points with the same value
				// as the closest point.
				spacialEnvelope.sort(spacialEnvelopePointComparator);
				
				SpacialEnvelopePoint firstSpacialPoint = spacialEnvelope.getFirst();
				if (firstSpacialPoint.getPosition() > 0)
				{
					SpacialEnvelopePoint newFirstSpacialPoint(0, firstSpacialPoint.getX(),
                                                              firstSpacialPoint.getY(),
                                                              firstSpacialPoint.getZ());
					spacialEnvelope.addSorted(spacialEnvelopePointComparator, newFirstSpacialPoint);
				}
				SpacialEnvelopePoint lastSpacialPoint = spacialEnvelope.getLast();
				int lengthOfThisRegion = audioRegionToModify->endPosition - audioRegionToModify->startPosition;
				if (lastSpacialPoint.getPosition() < lengthOfThisRegion )
				{
					SpacialEnvelopePoint newLastSpacialPoint(lengthOfThisRegion,
                                                             firstSpacialPoint.getX(),
                                                             firstSpacialPoint.getY(),
                                                             firstSpacialPoint.getZ());
					spacialEnvelope.addSorted(spacialEnvelopePointComparator, newLastSpacialPoint);
				}
				
				//DEBUGGING:
				// firstGainPoint = (AudioEnvelopePoint*)gainEnvelope[0];
				// DBG(String(firstGainPoint->getPosition()) + T(", ") + String(firstGainPoint->getValue()));
			}
			
			audioRegionToModify->audioSourceAmbipanning->setSpacialEnvelope (spacialEnvelope);
			return true;
		}
		else
		{
			DBG(T("AudioRegionMixer: Can't attach a spacial envelope to the region because the specified spacial Envelope is empty."))
			return false;
		}
		
	}
	else
	{
		DBG(T("AudioRegionMixer: Can't attach a gain envelope to the region because the specified regionID can't be found."))
		return false;
	}	
}

void AudioRegionMixer::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
	DBG(T("AudioRegionMixer: prepareToPlay called."));
	
	samplesPerBlockExpected = samplesPerBlockExpected_;
	sampleRate = sampleRate_;
	
	for (int i = regions.size(); --i >= 0;)
	{		
		((AudioRegion*)regions[i])->audioSourceAmbipanning
		  ->prepareToPlay(samplesPerBlockExpected, sampleRate);
	}
	
}

// Implementation of the AudioSource method.
void AudioRegionMixer::releaseResources()
{
	DBG(T("AudioRegionMixer: releaseResources called."));
	
	for (int i = regions.size(); --i >= 0;)
	{		
		((AudioRegion*)regions[i])->audioSourceAmbipanning
		->releaseResources();
	}
}

// Implements the PositionableAudioSource method.
void AudioRegionMixer::setNextReadPosition (int64 newPosition)
{
	// DBG(T("AudioRegionMixer: setNextReadPosition called."));
	
	nextPlayPosition = newPosition;
}

// Implementation of the AudioSource method.
void AudioRegionMixer::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	
	// DBG(T("AudioRegionMixer: nr of channels = ") + String(info.buffer->getNumChannels()));

	if (info.numSamples > 0)
	{
		// Zero the buffer of info. Will soon add regions to it (if there are any).
		info.clearActiveBufferRegion();
		
		tempBuffer.setSize (jmax (1, info.buffer->getNumChannels()),
							info.buffer->getNumSamples());
		AudioSourceChannelInfo tempInfo;
		tempInfo.buffer = &tempBuffer;
		tempInfo.startSample = 0;
		
		AudioRegion* currentAudioRegion;
		const int startOfThisChunk = nextPlayPosition;
		const int endOfThisChunk = nextPlayPosition + info.numSamples;
		for (int i = regions.size(); --i >= 0;)
		{	
			currentAudioRegion = (AudioRegion*)regions[i];
			if (currentAudioRegion->startPosition < endOfThisChunk 
				&& currentAudioRegion->endPosition >= startOfThisChunk)
			{
				// the next two variables are still measured in absolute samples on the timeline
				int startPositionOfCurrentRegionInThisChunk = jmax(startOfThisChunk,
													currentAudioRegion->startPosition);
				int endPositionOfCurrentRegionInThisChunk = jmin(endOfThisChunk,
												  currentAudioRegion->endPosition);
				
				int numberOfSamplesOfCurrentRegionInThisChunk
				     = endPositionOfCurrentRegionInThisChunk - startPositionOfCurrentRegionInThisChunk;
				
				// place the "virtual reading head" to the right position in the (multi channel) audio file
				currentAudioRegion->audioSourceAmbipanning->setNextReadPosition(
				  startPositionOfCurrentRegionInThisChunk
				  - currentAudioRegion->startPositionOfAudioFileInTimeline);
				
				// get the desired fragment of the audio file
				tempInfo.numSamples = numberOfSamplesOfCurrentRegionInThisChunk;
				currentAudioRegion->audioSourceAmbipanning->getNextAudioBlock(tempInfo);
				
				// add it to the buffer that will be returned
				int startSampleInTheBuffer = startPositionOfCurrentRegionInThisChunk - startOfThisChunk;
				for (int chan = 0; chan < info.buffer->getNumChannels(); ++chan)
				{
                    info.buffer->addFrom (chan, info.startSample + startSampleInTheBuffer , tempBuffer, 
										  chan, 0, numberOfSamplesOfCurrentRegionInThisChunk);
				}
			}
		}
	}
}

// Implements the PositionableAudioSource method.
int64 AudioRegionMixer::getNextReadPosition() const
{
	// DBG(T("AudioRegionMixer: getNextReadPosition called."));
	
	return nextPlayPosition;
}

// Implements the PositionableAudioSource method.
int64 AudioRegionMixer::getTotalLength() const
{
	// DBG(T("AudioRegionMixer: getTotalLength called."));

	// --------------------------------------
	// TODO: Think about what to return here!
	// --------------------------------------
	
	//return totalLength;  // in the arranger the playhead will stop at the end of the last region
	return INT_MAX - 1;  // in the arranger the playhead won't stop at the end of the last region
}

// Implements the PositionableAudioSource method.
bool AudioRegionMixer::isLooping() const
{
	// DBG(T("AudioRegionMixer: isLooping called."));
	
	// temp
	//return ((AudioRegion*)regions[0])->audioFormatReaderSource
    //->isLooping();
	return false;
}

bool AudioRegionMixer::findRegion(const int regionID, int& index)
{
	bool foundTheRegion = false;
	
	// find the index of the region in the VoidArray regions
	for (int i = 0; i < regions.size(); i++)
	{
		AudioRegion* audioRegionWithIndexI = (AudioRegion*)regions[i];	
		if (audioRegionWithIndexI->regionID == regionID)	
		{
			foundTheRegion = true;		
			index = i;		
			break;	
		}
	}
	
	return foundTheRegion;
}

	
//END_JUCE_NAMESPACE