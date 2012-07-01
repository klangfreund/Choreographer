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
#include "SpacialPosition.h"
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
    
    /**
     Calculates the value of the continuous signal at an arbitrary position,
     using the formula
     
     \f[ y(t) = \sum_{k \in \mathbb{Z}} x[k]h(t-kT) \f]
     
     where \f$h(.)\f$ is the impulse response of a LTI filter and \f$T\f$ is a
     real number. (This is equation (2.16) in the lecture note by Hans-Andrea
     Loeliger ZSSV 2011)
     We choose T = 1/samplerate and \f$h(.)\f$ the impulse response of the
     ideal lowpass filter with cutoff frequency f_c = 20kHz.
     
     We normalize the parameters and h
     (see 120327_ambipanning_interpolation.tif) and get
     
     \f[ y(t_n) = \sum_{k \in \mathbb{Z}} x[k]h(t_n - k) \f]
     
     \f[ h(t_n) = \frac{sin(2 \pi f_{cn} t_n)}{2 \pi f_{cn} t_n}
                = \sinc(2 f_{cn} t_n) \f]
     
     where:
     - \f$t_n\f$ is measured in samples. E.g. \f$t_n = 30.5\f$ means the time
       exactly between samples 30 and 31.
     - \f$f_{cn} = f_c / SR \f$ is the normalized cutoff frequency.

     Remark: By de l'Hopital: h(0) = 1.
     
     @param sampleRightBefore   The sample that comes right before the position
                                t_n we are looking for.
     @param remainder           Together with the sampleRightBefore, this
                                specifies t_n.
                                t_n = (position of sampleRightBefore) + remainder.
     */
    float interpolate (float * sampleRightBefore, double remainder);
    
    /**
     Returns the windowed impulse response of the ideal
     low pass filter (approximated, using a lookup table).
     
     Impulse response of the ideal low pass filter:
     
     \f[ h(t) = \frac{sin(2 \pi f_{cn} t)}{2 \pi f_{cn} t}
     = \sinc(2 f_{cn} t) \f]
     
     The raised-cosine windowing is done according to equation (2.77) in the
     lecture notes of Hans-Andrea Loeliger ZSSV 2011.
     
     \f[ w(t) = 0.5 + \left( 1 + \cos\left( \frac{2 \pi t)}{interpolationOrder + 2} \f]
     
     for -halfTheInterpolationOrder < t < halfTheInterpolationOrder.
     Outside of this interval w(t_n) = 0.
     
     This interpolate method looks up the requested values in the array
     valuesOfH.
     This interpolate method is used exclusively by the interpolate method.
     
     
     @param     t   abs(t) must be <= halfTheInterpolationOrder.
                    h does not check this condition!
     
     @return    approximation of h(t)*w(t)
     */
    double h(double t);
    
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
    
    AudioSampleBuffer sourceBuffer;
    /** This stores the samples from the audioSourceGainEnvelope needed
     for the interpolation.
     */
    AudioSourceChannelInfo sourceInfo;  // used in getNextAudioBlock(..).
    
    
    // Interpolation
    // -------------
    
    /** Half the value of the interpolation order. */
    static int halfTheInterpolationOrder;
    
    static int interpolationStepsPerUnit;
    
    /** Cutoff frequency for the (close to) ideal low pass filter
     used for the interpolation.
     
     Please choose its value below the nyquist frequency
     sampleRate/2.
     */
    static double cutoffFrequencyOfInterpolationLPF;
    
    static double pi;

    /** Holds the values of the impulse response h. */
    static Array<double> valuesOfH;
    
    /** This will calculate (2*halfTheInterpolationOrder+1)*interpolationStepsPerUnit values of the impulse response h.
     
     You have to set the desired values for halfTheInterpolationOrder and 
     interpolationStepsPerUnit before calling this.
     
     @return    always true. See __recalculateH.
     */
    static bool recalculateH(double sampleRate);
    
    /** A dummy variable which enables us to call recalculateH()
     at the end of the cpp file.
     
     All we would have liked to do is to call AudioSourceDopplerEffect::recalculateH(). 
     Sadly, the C++ compiler doesn't allow this directly. Thats why the dummy 
     variable __recalculateH exists. Thanks to this we can call
     bool AudioSourceDopplerEffect::__recalculateH = AudioSourceDopplerEffect::recalculateH();
     
     source: http://www.codeproject.com/Articles/18314/Static-Initialization-Function-in-Classes
     */
    static bool __recalculateH;
		
	JUCE_LEAK_DETECTOR (AudioSourceDopplerEffect);
};


#endif   // __AUDIOSOURCEDOPPLEREFFECT_HEADER__
