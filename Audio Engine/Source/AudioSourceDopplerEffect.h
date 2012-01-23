/*
 *  AudioSourceAmbipanning.h
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 120104.
 *  Copyright 2012. All rights reserved.
 *
 */

#ifndef __AUDIOSOURCEDOPPLEREFFECT_HEADER__
#define __AUDIOSOURCEDOPPLEREFFECT_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "SpacialEnvelopePoint.h"
#include "AudioSourceGainEnvelope.h"

//==============================================================================
/**
 TODO
 */
class JUCE_API AudioSourceDopplerEffect  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Constructor.
	 */
    AudioSourceDopplerEffect (AudioSourceGainEnvelope& audioSourceGainEnvelope_,
                              double sampleRate_);
	
    /** Destructor.
     */
    ~AudioSourceDopplerEffect();
	
	//==============================================================================
    /** Implementation of the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);
	
    /** Implementation of the AudioSource method. */
    void releaseResources ();
	
    /** Implements the PositionableAudioSource method. */
    void setNextReadPosition (int64 newPosition);
    
    /** Implementation of the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& info);
	
    /** Implements the PositionableAudioSource method. */
    int64 getNextReadPosition () const;
	
    /** Implements the PositionableAudioSource method. */
    int64 getTotalLength () const;
	
	/** Implements the PositionableAudioSource method. */
    bool isLooping () const;
	
	//==============================================================================

	/**
	 Sets a new spacial envelope which determines the location in space of the
     sound source in relation to the time. It also contains the distance delay
     for each point of the envelope, which is used here.
     This class makes a copy of the newSpacialEnvelope.
	 */
	void setSpacialEnvelope (const Array<SpacialEnvelopePoint>& newSpacialEnvelope);
	
private:
	/**
	 Figures out between which audioEnvelopePoints we are right now
	 and sets up
     - nextSpacialPointIndex
     - nextSpacialPoint
     - previousSpacialPoint
     - delayOnCurrentSample
     - delayDelta.
	 */
	inline void prepareForNewPosition (int newPosition,
                                       int nextSpacialPointIndex_ = 1);
    
    double sampleRate;
    double oneOverSampleRate;
    double samplesPerBlockExpected;
    
    /** Holds the SpacialEnvelopePoints which define the
     position / movement of the audio source in space over time.
     It is assumed by the code that the SpacialEnvelopePoints are
     ordered in this array according to their position in time.
     */
	OwnedArray<SpacialEnvelopePoint> spacialEnvelope;
    
	/** This is used by AudioSourceAmbipanning::setSpacialEnvelope and
	 by AudioSourceAmbipanning::getNextAudioBlock when a new envelope is engaged.
	 */
	OwnedArray<SpacialEnvelopePoint> newSpacialEnvelope;
    SpacialEnvelopePointComparator spacialEnvelopePointComparator;
    bool newSpacialEnvelopeSet;
    bool constantSpacialPosition;
    int constantSpacialPositionDelayTimeInSamples;
    SpacialEnvelopePoint * previousSpacialPoint;
    SpacialEnvelopePoint * nextSpacialPoint;
    int nextSpacialPointIndex;
    
    /** 
     */
    AudioSourceGainEnvelope& audioSourceGainEnvelope;
    
    int nextPlayPosition;
    int audioBlockEndPosition;
    
    /**
     The delay of the current sample, measured in seconds.
     */
    double delayOnCurrentSample;
    
    /**
     The time difference between two samples including the delay difference.
     */
    double timeDifference;
    
    AudioSampleBuffer sourceBuffer;
    /** This stores the samples from the audioSourceGainEnvelope needed
     for the interpolation.
     */
    AudioSourceChannelInfo sourceInfo;  // used in getNextAudioBlock(..).
		
	JUCE_LEAK_DETECTOR (AudioSourceDopplerEffect);
};


#endif   // __AUDIOSOURCEDOPPLEREFFECT_HEADER__
