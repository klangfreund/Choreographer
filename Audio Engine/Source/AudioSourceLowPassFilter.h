/*
 *  AudioSourceDopplerEffect.h
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 120402.
 *  Copyright 2012. All rights reserved.
 *
 */

#ifndef __AUDIOSOURCELOWPASSFILTER_HEADER__
#define __AUDIOSOURCELOWPASSFILTER_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "SpacialEnvelopePoint.h"
#include "SpacialPosition.h"
#include "AudioSourceGainEnvelope.h"

//==============================================================================
/**
 Distance based low pass filter.
 */
class JUCE_API AudioSourceLowPassFilter  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Constructor.
	 */
    AudioSourceLowPassFilter (PositionableAudioSource * positionableAudioSource_,
                              double sampleRate_);
	
    /** Destructor.
     */
    ~AudioSourceLowPassFilter();
	
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
    
    void setSource (PositionableAudioSource * positionableAudioSource_);
    
    /**
     Set the distance where the low pass filter cutoff frequency is
     at 10.5kHz.
     The falloff curve is defined as an exponential decrease:
        cutoffAtOrigin = 21000.0;
        lambda = log(2.0)/distanceWithHalfTheOpenCutoffFrequency;
        cutoffFrequency = cutoffAtOrigin * exp(-lambda * currentSpacialPosition.getDistance());
     */
    static void setDistanceWithHalfTheOpenCutoffFrequency(double distanceWithHalfTheOpenCutoffFrequency);
	
private:
	/**
	 It figures out the other parameters given the newPosition.
     Either the *nextSpacialPointIndex_ is really the next one seen from the
     newPosition, or in needs to be set to 1 before calling this.
     
     @param newPosition             The position in time (in samples) of interest.
     @param nextSpacialPointIndex_  Will be modified.
                                    This must be lower or equal to the index of
                                    the next spacial point in the envelope.
                                    If the value is lower, then it will be
                                    increased until it is this index.
     @param previousSpacialPoint_   Will be modified.
                                    The envelope point that comes before (or at
                                    the same time as the)
                                    point at the newPosition (in time).
     @param nextSpacialPoint_       Will be modified.
                                    The envelope point that comes after the
                                    point at the newPosition (in time).
     @param currentSpacialPosition_ Will be modified.
                                    The position in space of the point at the
                                    time position newPosition.
     @param deltaSpacialPosition_   Will be modified.
                                    The difference in space of two adjecent
                                    samples between the previousSpacialPoint_
                                    and the nextSpacialPoint_.
	 */
	inline void prepareForNewPosition (int newPosition,
                                       int * nextSpacialPointIndex_,
                                       SpacialEnvelopePoint ** previousSpacialPoint_,
                                       SpacialEnvelopePoint ** nextSpacialPoint_,
                                       SpacialPosition * currentSpacialPosition_);
    
    double sampleRate;
    double samplesPerBlockExpected;
    
    /** Holds the SpacialEnvelopePoints which define the
     position / movement of the audio source in space over time.
     It is assumed by the code that the SpacialEnvelopePoints are
     ordered in this array according to their position in time.
     */
	OwnedArray<SpacialEnvelopePoint> spacialEnvelope;
    bool constantSpacialPosition;
    
    SpacialEnvelopePoint * previousSpacialPoint;
    SpacialEnvelopePoint * nextSpacialPoint;
    int nextSpacialPointIndex;
    
    /** The source that provides the samples to filter.
     */
    PositionableAudioSource* positionableAudioSource;
    
    int nextPlayPosition;
    
    SpacialPosition currentSpacialPosition;
    
    static double lambda;

    /** The actual filter. */
    IIRFilter iirFilter;
    
    /** Used to lock the section in setSpacialEnvelope. */
    CriticalSection lock;
    		
	JUCE_LEAK_DETECTOR (AudioSourceLowPassFilter);
};


#endif   // __AUDIOSOURCELOWPASSFILTER_HEADER__
