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
	
    /** Implementation of the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& info);
	
    //==============================================================================
    /** Implements the PositionableAudioSource method. */
    void setNextReadPosition (int64 newPosition);
	
    /** Implements the PositionableAudioSource method. */
    int64 getNextReadPosition () const;
	
    /** Implements the PositionableAudioSource method. */
    int64 getTotalLength () const;
	
	/** Implements the PositionableAudioSource method. */
    bool isLooping () const;
	
	//==============================================================================

	/**
	 Sets a new spacial envelope which determines the location in space of the
     sound source in relation to the time.
	 */
	void setSpacialEnvelope (const Array<SpacialEnvelopePoint>& newSpacialEnvelope);
	
private:
	/**
	 Figures out between which audioEnvelopePoints we are right now
	 and sets up nextSpacialPointIndex, previousSpacialPoint and nextSpacialPoint.
	 It also calculates the values of the float-arrays channelFactorAtPreviousSpacialPoint,
	 channelFactorAtNextSpacialPoint, channelFactorDelta and channelFactor.
	 */
	inline void prepareForNewPosition (int newPosition);
    
    double sampleRate;
    double samplesPerBlockExpected;
    
    /** Holds the SpacialEnvelopePoints which define the
     position / movement of the audio source in space over time.
     It is assumed by the code that the SpacialEnvelopePoints are
     ordered in this array according to their position in time.
     */
	Array<SpacialEnvelopePoint> spacialEnvelope;
    
	/** This is used by AudioSourceAmbipanning::setSpacialEnvelope and
	 by AudioSourceAmbipanning::getNextAudioBlock when a new envelope is engaged.
	 */
	Array<SpacialEnvelopePoint> newSpacialEnvelope;
    SpacialEnvelopePointComparator spacialEnvelopePointComparator;
    bool newSpacialEnvelopeSet;
    bool constantSpacialPosition;
    SpacialEnvelopePoint previousSpacialPoint;
    SpacialEnvelopePoint nextSpacialPoint;
    int nextSpacialPointIndex;
    
    /** 
     */
    double audioBlockStretchFactor;
    int maxSamplesPerBlockForSource;
    AudioSourceGainEnvelope& audioSourceGainEnvelope;
    
    int nextPlayPosition;
    int audioBlockEndPosition;
    
    /**
     The delay of the current sample, measured in samples.
     */
    double delayOnCurrentSample;
    
    /**
     The delay difference between two samples.
     */
    double delayDelta;
    
    AudioSampleBuffer sourceBuffer;
    /** This stores the samples from the audioSourceGainEnvelope needed
     for the interpolation.
     */
    AudioSourceChannelInfo sourceInfo;  // used in getNextAudioBlock(..).
		
	JUCE_LEAK_DETECTOR (AudioSourceDopplerEffect);
};


#endif   // __AUDIOSOURCEDOPPLEREFFECT_HEADER__
