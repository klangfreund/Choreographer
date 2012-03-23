/*
 *  AudioSourceDopplerEffect.h
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

/** Defines a position in space.
 
 Exclusively used in AudioSourceDopplerEffect.
 */
struct SpacialPosition
{
    /** x coordinate in space. */
    double x;
    double y;
    double z;
    
    /** The constant value of 1/(speed of sound) in meters per second. */
    // Initialized in the file AudioSourceDopplerEffect.cpp.
    static const double oneOverSpeedOfSound; // = 1.0/340.0 = = 0.00294 m/s

    /** Constructor */
    SpacialPosition ()
    : x (0.0),
    y (0.0),
    z (0.0),
    delay (0.0)
    {
    }
    
    /** Constructor */
    SpacialPosition (double x_, double y_, double z_)
    : x (x_),
      y (y_),
      z (z_)
    {
        calculateDelay();
    }
    
    /** Constructor */
    SpacialPosition (const SpacialEnvelopePoint & spacialEnvPoint)
    : x (spacialEnvPoint.getX()),
      y (spacialEnvPoint.getY()),
      z (spacialEnvPoint.getZ())
    {
        calculateDelay();
    }
    
    /** Returns the delay time (in seconds) from this spacial position (x,y,z)
     to the origin (0,0,0). */
    double getDelay()
    {
        return delay;
    }
        
    /** Comparison operator to check for equality. */    
    bool operator== (const SpacialPosition & other) const
    {
        if (x == other.x && y == other.y && z == other.z)
            return true;
        else
            return false;
    }
    
    /** Comparison operator to check for inequality. */    
    bool operator!= (const SpacialPosition & other) const
    {
        return !(*this == other);
    }
    
    SpacialPosition operator+= (const SpacialPosition & other) const
    {
        SpacialPosition result = *this;
        result.x += other.x;
        result.y += other.y;
        result.z += other.z;
        result.calculateDelay();
        return result;
    }
    
    SpacialPosition operator+ (const SpacialPosition & other) const
    {
        SpacialPosition result = *this;
        result.x += other.x;
        result.y += other.y;
        result.z += other.z;
        result.calculateDelay();
        return result;
    }

    SpacialPosition operator- (const SpacialPosition & other) const
    {
        SpacialPosition result = *this;
        result.x -= other.x;
        result.y -= other.y;
        result.z -= other.z;
        result.calculateDelay();
        return result;
    }
    
    /** The inner product */
    double operator* (const SpacialPosition & other) const
    {
        return x*other.x + y*other.y + z*other.z;
    }
    
    /** The product with a scalar on the right hand side. */
    SpacialPosition operator* (double scalar) const
    {
        SpacialPosition result = *this;
        result.x *= scalar;
        result.y *= scalar;
        result.z *= scalar;
        result.calculateDelay();
        return result;
    }
    
    /** The product with a scalar on the left hand side. */
    friend SpacialPosition operator*(double scalar, const SpacialPosition & rhs)
    {return rhs * scalar;}
    
private:
    
    double delay;
    void calculateDelay()
    {
        // return sqrt(*this * *this) * oneOverSpeedOfSound;
        delay = 100. * sqrt(*this * *this) * oneOverSpeedOfSound;
    }
    

};

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
                                       SpacialPosition * currentSpacialPosition_,
                                       SpacialPosition * deltaSpacialPosition_);
    
    /**
     Figures out the closest point on a line to the origin.
     The line is defined by the two points firstPoint and secondPoint.
     
     @return If the closest point lies in between the first and the
             second point.
     */
    inline bool closestPointInBetween (const SpacialPosition & firstPoint, 
                                       const SpacialPosition & secondPoint,
                                       SpacialPosition & closestPoint);
    
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
    SpacialEnvelopePointPointerComparator spacialEnvelopePointPointerComparator;
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
//    double delayOnCurrentSample;
    
    /**
     The time difference between two samples including the delay difference.
     */
//    double timeDifference;
    
    SpacialPosition currentSpacialPosition;
    
    SpacialPosition deltaSpacialPosition;
    
    AudioSampleBuffer sourceBuffer;
    /** This stores the samples from the audioSourceGainEnvelope needed
     for the interpolation.
     */
    AudioSourceChannelInfo sourceInfo;  // used in getNextAudioBlock(..).
		
	JUCE_LEAK_DETECTOR (AudioSourceDopplerEffect);
};


#endif   // __AUDIOSOURCEDOPPLEREFFECT_HEADER__
