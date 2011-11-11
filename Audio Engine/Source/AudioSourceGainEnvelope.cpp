/*
 *  AudioSourceGainEnvelope.cpp
 *  Choreographer
 *
 *  Created by sam on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#include "AudioSourceGainEnvelope.h"

AudioSourceGainEnvelope::AudioSourceGainEnvelope (AudioFormatReader* const audioFormatReader, 
												  double sampleRateOfTheAudioDevice)
    : nextPlayPosition (-1),         // such that the values in setNextReadPosition(..) will be set.
      audioBlockEndPosition (-2),
      previousGainPoint (0),
      nextGainPoint (0),
      nextGainPointIndex (0),
      gainValue (1.0f),
      gainDelta (0.0f)
{
	DEB("AudioSourceGainEnvelope: constructor called.")
	
	audioFormatReaderSource = new AudioFormatReaderSource (audioFormatReader, true);

	// ENTWEDER
//	positionableResamplingAudioSource 
//	  = new PositionableResamplingAudioSource (audioFormatReaderSource, true);
//	  // second argument: deleteSourceWhenDeleted
//	double sampleRateOfTheFile = audioFormatReader->sampleRate;
//	positionableResamplingAudioSource->setResamplingRatio(sampleRateOfTheFile/sampleRateOfTheAudioDevice);
//	bufferingAudioSource = new BufferingAudioSource (positionableResamplingAudioSource, true, 32768);

	// ODER (nur diese eine Zeile)
	bufferingAudioSource = new BufferingAudioSource (audioFormatReaderSource, true, 32768);	
	  // This buffer is needed because the audioFormatReaderSource is slow (because reading from
	  //   hard drive is a slow operation - compared with the time given for filling the audio
	  //   buffer of a audio callback)
	  // second argument: deleteSourceWhenDeleted
	newGainEnvelopeSet = false;
	constantGain = true;
}

AudioSourceGainEnvelope::~AudioSourceGainEnvelope()
{
	DEB("AudioSourceGainEnvelope: destructor called.")
	delete bufferingAudioSource;  // this also deletes the positionableResamplingAudioSource
								  // and the audioFormatReaderSource.
	
	// delete the gain envelope
	for (int i = gainEnvelope.size(); --i >= 0;)
	{
		AudioEnvelopePoint* audioEnvelopePointToDelete = (AudioEnvelopePoint*)gainEnvelope[i];
		delete audioEnvelopePointToDelete;
	}
}

/** Implementation of the AudioSource method. */
void AudioSourceGainEnvelope::prepareToPlay (int samplesPerBlockExpected, double sampleRate)
{
	bufferingAudioSource->prepareToPlay (samplesPerBlockExpected, sampleRate);
}

/** Implementation of the AudioSource method. */
void AudioSourceGainEnvelope::releaseResources()
{
	bufferingAudioSource->releaseResources();
}

/** Implements the PositionableAudioSource method. */
void AudioSourceGainEnvelope::setNextReadPosition (int64 newPosition)
{
	// if the newPosition is not at the expected position, right after the end
	// of the last audio block
	if (audioBlockEndPosition != newPosition && !constantGain)
	{
		DEB("AudioSourceGainEnvelope.setNextReadPosition: newPosition = " + String(newPosition))
		DEB("AudioSourceGainEnvelope.setNextReadPosition: expected newPosition: " 
			+ String(audioBlockEndPosition))

		// figure out between which audioEnvelopePoints we are right now
		// and set up all variables needed by getNextAudioBlock(..)
		prepareForNewPosition(newPosition);	
	}
	
	nextPlayPosition = newPosition;
	bufferingAudioSource->setNextReadPosition (newPosition);
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceGainEnvelope::getNextReadPosition() const
{
	return bufferingAudioSource->getNextReadPosition();
}

/** Implementation of the AudioSource method. */
void AudioSourceGainEnvelope::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	audioBlockEndPosition = nextPlayPosition + info.numSamples; // used here and in setNextReadPosition.
																// It referes to the first sample after
																// the current audio block.
	bufferingAudioSource->getNextAudioBlock(info);
	
	// This will be executed when a new gain envelope has been set with setGainEnvelope(..).
	if (newGainEnvelopeSet)
	{
		Array<void*> oldGainEnvelope = gainEnvelope;
		gainEnvelope = newGainEnvelope;
		previousGainValue = gainValue; // This is used in the info.buffer->applyGainRamp(..)
		// a couple of lines below to generate a smooth gain transition from the current to 
		// the gain value of the new envelope.
		
		// delete content of the old gain envelope
		for (int i = oldGainEnvelope.size(); --i >= 0;)
		{
			AudioEnvelopePoint* audioEnvelopePointToDelete = (AudioEnvelopePoint*)oldGainEnvelope[i];
			delete audioEnvelopePointToDelete;
		}
		
		if (gainEnvelope.size() == 1) // by the way: size() == 0 can't be, this was
								      // checked in setGainEnvelope(..)
		{
			constantGain = true;
			nextGainPoint = (AudioEnvelopePoint*)gainEnvelope[0];
			gainValue = nextGainPoint->getValue();
		}
		
		// if the envelope contains more than 1 point
		else
		{
			constantGain = false;
			prepareForNewPosition(audioBlockEndPosition); // The variables are set up for the
			  // next call of getNextAudioBlock(..)
		}
		
		
		info.buffer->applyGainRamp(0, info.startSample, info.numSamples, previousGainValue, gainValue);
		newGainEnvelopeSet = false;
	}
	
	// This is the regular case
	else
	{	
		// If there is only one point in the gain envelope
		if (constantGain)
		{
			info.buffer->applyGain(0, info.startSample, info.numSamples, gainValue);
			  // arguments
			  //    channel = 0
			  //    startSample = info.startSample
			  //    numSamples = info.numSamples
			  //    gain = gainValue
		}
		
		// If there are multiple points in the gain envelope
		else
		{		
			currentPosition = nextPlayPosition;
			
			// Points to the first sample in the audio block.
			float* sample = info.buffer->getSampleData(0, info.startSample); 
	    	// First argument: channelNumber = 0, since this class is made
		    //     for mono signals only.
		    // Second argument: sampleOffset = info.startSample
			while (true)
			{
				// if the next gain point is outside of the current audio block
				// (audioBlockEndPosition is the position of to the first sample
				//  after the current block)
				if (nextGainPoint->getPosition() >= audioBlockEndPosition )
				{
					numberOfRemainingSamples = audioBlockEndPosition - currentPosition;
					while (--numberOfRemainingSamples >= 0)
					{
						*sample++ *= gainValue;
						gainValue += gainDelta;
					}
					break;
				}
				
				// if the next gain point is inside the current audio block
				else
				{
					// apply the gain envelope up to the sample before the nextGainPoint
					numberOfRemainingSamples = nextGainPoint->getPosition() - currentPosition;
					while (--numberOfRemainingSamples >= 0)
					{
						*sample++ *= gainValue;
						gainValue += gainDelta;
					}
					
					// apply the gain to the sample at the nextGainPoint position
					gainValue = nextGainPoint->getValue();
					*sample++ *= gainValue;
					
					currentPosition = nextGainPoint->getPosition() + 1;
				    // currentPosition tells you the next sample to apply the gain
					
					previousGainPoint = nextGainPoint;
					nextGainPointIndex++;
					nextGainPoint = (AudioEnvelopePoint*)gainEnvelope[nextGainPointIndex];
					
					// figure out gainDelta
					int distance = nextGainPoint->getPosition() - previousGainPoint->getPosition();
					gainDelta = (nextGainPoint->getValue() - previousGainPoint->getValue()) / (float)distance;
					
					gainValue += gainDelta;
				}
			}			
		}
	}
}

int64 AudioSourceGainEnvelope::getTotalLength() const
{
	return bufferingAudioSource->getTotalLength();
}

/** Implements the PositionableAudioSource method. */
bool AudioSourceGainEnvelope::isLooping() const
{
	return bufferingAudioSource->isLooping();
}

void AudioSourceGainEnvelope::setGainEnvelope(Array<void*> newGainEnvelope_)
{
	DEB("AudioSourceGainEnvelope: setGainEnvelope called.")
	
	if (newGainEnvelope_.size() != 0)
	{
		// this Array must be sorted for the code in getNextAudioLoop(..)
		// to work.
		newGainEnvelope_.sort(audioEnvelopePointComparator);
		
		{
			const ScopedLock sl (callbackLock);
			
			newGainEnvelope = newGainEnvelope_;
			newGainEnvelopeSet = true; // when set, the gain is faded from the
			  // old gain envelope to the new one, in the interval
			  // of one audio block in the getNextAudioBlock(..).
			  // This avoids audible clicks.
		}
	}
	else
	{
		DEB("AudioSourceGainEnvelope: The newGainEnvelope is empty! The gain "
            "envelope hasn't been changed.")
	}
}

inline void AudioSourceGainEnvelope::prepareForNewPosition(int newPosition)
{
	// figure out between which audioEnvelopePoints we are right now
	// and set up all variables needed by getNextAudioBlock(..)
	nextGainPointIndex = 1; // since the first audioEnvelopePoint has to be at position 0 
	while (((AudioEnvelopePoint*)gainEnvelope[nextGainPointIndex])->getPosition() <= newPosition)
	{
		nextGainPointIndex++;
	}
	previousGainPoint = (AudioEnvelopePoint*)gainEnvelope[nextGainPointIndex - 1];
	nextGainPoint = (AudioEnvelopePoint*)gainEnvelope[nextGainPointIndex];
	int distance = nextGainPoint->getPosition() - previousGainPoint->getPosition();
	gainDelta = (nextGainPoint->getValue() - previousGainPoint->getValue()) / (float)distance;
	
	int distanceFromPreviousGainPointPosToCurrentPos = newPosition - previousGainPoint->getPosition();
	gainValue = previousGainPoint->getValue()
	+ gainDelta*(float)(distanceFromPreviousGainPointPosToCurrentPos);
	// this is the gainValue for the sample at position newPosition
}