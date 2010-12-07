/*
 *  AudioSourceGainEnvelope.h
 *  Choreographer
 *
 *  Created by sam on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __AUDIOSOURCEGAINENVELOPE_HEADER__
#define __AUDIOSOURCEGAINENVELOPE_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "modified Juce Classes/juce_PositionableResamplingAudioSource.h"

//==============================================================================
/**
 Used by AudioSourceGainEnvelope, ...
 */
class JUCE_API  AudioEnvelopePoint
{
public:
	AudioEnvelopePoint()
		: position (0),
	      value (1.0f)
	{
	}
	
	AudioEnvelopePoint(int position_, float value_)
	    : position (position_),
	      value (value_)
	{
    }
	
	~AudioEnvelopePoint()
	{
	}
	
	void setPosition(const int& position_)
	{
		position = position_;
		
	}
	
	void setValue(const float& value_)
	{
		value = value_;
	}
	
	void setPositionAndValue(const int& position_, const float& value_)
	{
		position = position_;
		value = value_;
	}
	
	int getPosition()
	{
		return position;
	}
	
	float getValue()
	{
		return value;
	}
	
private:	
    /** The position in samples. */
    int position;
	
	/** The value at the specified position */
    float value;	
};

//==============================================================================
/**
 This comparator is needed for the sort function in a VoidArray of AudioEnvelopePoints.
 
 @see Array
 */
class JUCE_API AudioEnvelopePointComparator
{
public:
	AudioEnvelopePointComparator ()
	{
	}
	
	int compareElements (void* first, void* second) const
	{
		if (((AudioEnvelopePoint*)first)->getPosition() < ((AudioEnvelopePoint*)second)->getPosition())
		{
			return -1;
		}
		else if (((AudioEnvelopePoint*)first)->getPosition() > ((AudioEnvelopePoint*)second)->getPosition())
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
};

//==============================================================================
//==============================================================================
/**
 IMPORTANT: This is intended for mono signals only, i.e. only on the first channel
 the volume envelope is applied.
 
 @see PositionableAudioSource
 */
class JUCE_API  AudioSourceGainEnvelope  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Constructor: Creates an AudioSourceGainEnvelope.
	 *   The audioFormatReader argument is used by the audioFormatReaderSource.
	 */
    AudioSourceGainEnvelope (AudioFormatReader* const audioFormatReader,
							 double sampleRateOfTheAudioDevice);
	
    /** Destructor. */
    ~AudioSourceGainEnvelope();
	
	//==============================================================================
    /** Implementation of the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);
	
    /** Implementation of the AudioSource method. */
    void releaseResources();
	
    /** Implementation of the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& info);
	
    //==============================================================================
    /** Implements the PositionableAudioSource method. */
    void setNextReadPosition (int newPosition);
	
    /** Implements the PositionableAudioSource method. */
    int getNextReadPosition() const;
	
    /** Implements the PositionableAudioSource method. */
    int getTotalLength() const;
	
	/** Implements the PositionableAudioSource method. */
    bool isLooping() const;
	
	//==============================================================================
	/** 
	 @param newGainEnvelope			it will be deleted in the setGainEnvelope(..)
									or in the destructor, so you don't have to
									care about.
	 */
	void setGainEnvelope(Array<void*> newGainEnvelope);
	

private:
	inline void prepareForNewPosition(int newPosition);
	
	BufferingAudioSource* bufferingAudioSource;
	PositionableResamplingAudioSource* positionableResamplingAudioSource;
	AudioFormatReaderSource* audioFormatReaderSource;
	
	Array<void*> gainEnvelope;
	Array<void*> newGainEnvelope; // This is used by setGainEnvelope(..) and
	  // by getNextAudioBlock(..) when a new envelope is engaged.
	AudioEnvelopePointComparator audioEnvelopePointComparator;
	bool newGainEnvelopeSet;
	bool constantGain;
	
    int volatile nextPlayPosition;
	int currentPosition; // used in getNextAudioBlock(..) if the envelope contains more than one point.
	int audioBlockEndPosition;  // Used in setNextReadPosition(..) and set in
								// getNextAudioBlock(..) to determine if
								// the playhead is at an unpredictable position
								// and therefore the following variables have
								// to be recalculated.
								// It tells you the (position of the last sample
								// in the previously processed audio block) + 1
								// in samples, relative to the start of the audio
								// file.
	AudioEnvelopePoint* previousGainPoint;
	AudioEnvelopePoint* nextGainPoint;
	int nextGainPointIndex;
	float gainValue;
	float previousGainValue; // used in getNextAudioBlock(..) if there is a
	  // transition to a new envelope is going on.
	float gainDelta;
	int numberOfRemainingSamples;
	
	CriticalSection callbackLock;
};


#endif   // __AUDIOSOURCEGAINENVELOPE_HEADER__