/*
 *  AudioSourceAmbipanning.h
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __AUDIOSOURCEAMBIPANNING_HEADER__
#define __AUDIOSOURCEAMBIPANNING_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "SpacialEnvelopePoint.h"
#include "AudioSourceGainEnvelope.h"
#include "AudioSourceDopplerEffect.h"

//==============================================================================
/**
 Describes a point in space in cartesian coordinates.
 Used by the array AudioSourceAmbipanning::positionOfSpeaker.
 
 Here (like in other Ambisonics applications), the y axis
 is directed towards the front, the x axis is directed
 towards the right and the z axis is directed towards
 the sky.
 */
class JUCE_API  SpeakerPosition
{
public:
	SpeakerPosition();
	
	/** Constructor.
	 @param x_ x-coordinate in space.
	 @param y_ y-coordinate in space.
	 @param z_ z-coordinate in space.
	 */
	SpeakerPosition (const double& x_, 
                     const double& y_, 
                     const double& z_);
    
    SpeakerPosition (const SpeakerPosition& other);
	
	/** Destructor. */
	~SpeakerPosition ();
    
    /** The assignment operator.
     
     @param other   The source object from the right hand side.
     @return        This object to allow a=b=c like semantics.
     */
    const SpeakerPosition& operator= (const SpeakerPosition& other);
	
	/** Sets the x-coordinate in space. */
	void setX (const double& x_);
	
	/** Sets the y-coordinate in space. */
	void setY (const double& y_);
	
	/** Sets the z-coordinate in space. */
	void setZ (const double& z_);
	
	/** Sets the x-, y- and z-coordinate in space. */
	void setXYZ (const double& x_,
                 const double& y_,
                 const double& z_);
	
	/** Gets the x-coordinate in space. */
    double getX ();
    
	/** Gets the y-coordinate in space. */
    double getY ();
	
	/** Gets the z-coordinate in space. */
    double getZ ();
	
private:
	double x;
	double y;
	double z;
	
	JUCE_LEAK_DETECTOR (SpeakerPosition);
};

//==============================================================================
/**
 It takes the mono audio stream from an AudioSourceGainEnvelope (which it
 instantiates internally, given an AudioFormatReader) and returns as many
 audio streams as speakers are connected.
 The additional information needed for this calculation is the position
 in space for every instance of time. This is stored in the 
 AudioSourceAmbipanning::spacialEnvelope.

 The formula at the heart of this class is called Ambisonics Equivalent
 Panning (AEP) and looks like this:
 \f[ \textrm{gain}_{n}(t) 
     = \left( \frac{2 + x_{\textrm{speaker}_n} \cdot x_{\textrm{source}}
       + y_{\textrm{speaker}_n} \cdot y_{\textrm{source}}
       + z_{\textrm{speaker}_n} \cdot z_{\textrm{source}} }{2} \right)^{M}
       \cdot \textrm{distanceGain}(t), \f]
 where the coordinates have to be on the unit sphere. (To describe
 arbitrary points, an additional parameter \f$ r \f$ is used).
 This is done in AudioSourceAmbipanning::getNextAudioBlock and in
 AudioSourceAmbipanning::prepareForNewPosition.
 \f$M\f$ is the modified order of the approximation and 
 \f$\textrm{distanceGain}(t)\f$ takes the distance into account.
 Both values are calculated in AudioSourceAmbipanning::calculationsForAEP.
 AudioSourceAmbipanning::distanceMode determines how they are calculated.

 <ul>
 <li> distanceMode == 0: distanceGain := 1, modifiedOrder := order.
 <li> distanceMode == 1 and r<centerRadius:  
      \f[ \textrm{distanceGain} := 
      \left(\frac{r}{\textrm{centerRadius}}\right)^\textrm{centerExponent} \cdot 
      (1 - \textrm{centerAttenuation}) + \textrm{centerAttenuation} \f]
      \f[ \textrm{modifiedOrder} := \textrm{order} \cdot
      \frac{r}{\textrm{centerRadius}} \f]
 <li> distanceMode == 1 and r>=centerRadius:
      \f[ \textrm{distanceGain} := 
      10^{(r - \textrm{centerRadius}) \cdot 
      \textrm{dBFalloffPerUnit} \cdot 0.05} \f]
      \f[ \textrm{modifiedOrder} := \textrm{order} \f]
 <li> distanceMode == 2 and r<centerRadius:  
      \f[ \textrm{distanceGain} := 
      \left(\frac{r}{\textrm{centerRadius}}\right)^\textrm{centerExponent} \cdot 
      (1 - \textrm{centerAttenuation}) + \textrm{centerAttenuation} \f]
	  \f[ \textrm{modifiedOrder} := \textrm{order} \cdot
      \frac{r}{\textrm{centerRadius}} \f]
 <li> distanceMode == 2 and r>=centerRadius:
      \f[ \textrm{distanceGain} := 
      \left( r - \textrm{centerRadius} + 1 \right)^{\textrm{outsideCenterExponent}} \f]
	  \f[ \textrm{modifiedOrder} := \textrm{order} \f]
 </ul>
 
 The signal for the n-th speaker is
 \f[ \textrm{output}_{n}(t) = \textrm{gain}_{n}(t) \cdot \textrm{input}(t). \f]
 This is done in AudioSourceAmbipanning::getNextAudioBlock.


 */
class JUCE_API  AudioSourceAmbipanning  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Constructor: Creates an AudioSourceAmbipanning.
	 *   The audioFormatReader argument is used by the audioSourceGainEnvelope.
	 */
    AudioSourceAmbipanning (AudioFormatReader* const audioFormatReader,
							double sampleRateOfTheAudioDevice);
	
    /** Destructor. */
    ~AudioSourceAmbipanning();
	
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
     Enables or disables the buffering.
     
     After instanciation buffering is enabled. For realtime operation, buffering
     should always be engaged. For non-realtime operation (e.g. bounce 
     to disk), buffering should be disabled.
     */
    void enableBuffering (bool enable);
    
    /**
     Enables or disables the doppler effect.
     
     After instanciation it is disabled.
     */    
    void enableDopplerEffect (bool enable);
    
	/** 
	 @param newGainEnvelope		It will be deleted in the setGainEnvelope(..) of
								AudioSourceGainEnvelope or in the destructor of
								AudioSourceGainEnvelope, so you don't have to
								care about.
	 */
	void setGainEnvelope (Array<void*> newGainEnvelope);

	/**
	 Sets a new spacial envelope which determines the location in space of the
     sound source in relation to the time.
     
     @param newSpacialEnvelope  This array defines the movement of the sound
                                source over time in space. If it only contains
                                one point, this one defines the fix position at
                                every arbitrary moment in time. It it contains
                                multiple points they must be ordered according
                                to their position (in time). The first point
                                has to be at the (sample) position 0 according
                                to the audio file and the last point must be
                                at the sample lengthOfTheAudioFile.
	 */
	void setSpacialEnvelope (const Array<SpacialEnvelopePoint>& newSpacialEnvelope);
	
	/**
	 This is the place where the size/memory space for all arrays of this class is
	 allocated. It has to be called immediately after the number of speakers has
	 changed.
	 */
	void reallocateMemoryForTheArrays ();
	
	/**
	 Sets the order used in the Ambipanning calculation.
	 */
	static void setOrder(int order_);

	/** 
	 Sets the positions of the speakers.
	 */
	static void setPositionOfSpeakers(const Array<SpeakerPosition>& positionOfSpeaker_);

	/** 
	 Sets the distanceMode to 0. In this mode, distanceGain := 1, modifiedOrder := order.
	 */
	static void setDistanceModeTo0();
	
	/** 
	 Sets the distanceMode to 1. All parameters used in this mode need to be specified.
	 */
	static void setDistanceModeTo1(double centerRadius_, 
								   double centerExponent_,
								   double centerAttenuation_,
								   double dBFalloffPerUnit_);
	
	/** 
	 Sets the distanceMode to 2. All parameters used in this mode need to be specified.
	 */
	static void setDistanceModeTo2(double centerRadius_, 
								   double centerExponent_,
								   double centerAttenuation_,
								   double outsideCenterExponent_);
	
private:
	/**
	 Figures out between which audioEnvelopePoints we are right now
	 and sets up nextSpacialPointIndex, previousSpacialPoint and nextSpacialPoint.
	 It also calculates the values of the float-arrays channelFactorAtPreviousSpacialPoint,
	 channelFactorAtNextSpacialPoint, channelFactorDelta and channelFactor.
	 */
	inline void prepareForNewPosition (int newPosition);
	
	/**
	 Calculates the distanceGain and the modifiedOrder,
	 according to the chosen AudioSourceAmbipanning::distanceMode.
     r is also calculated and x, y, and z are normalised, such that they 
     describe the projection to the unit sphere.
	 */
	inline void calculationsForAEP (double& x, 
                                    double& y, 
                                    double& z, 
                                    double& r,
									double& distanceGain, 
                                    double& modifiedOrder);
	
	static int order;
	static Array<SpeakerPosition> positionOfSpeaker;	
	// for the distance calculations
	static int distanceMode;		///< Determines which algorithm is chosen to 
                                    ///< calculate the 
									///< distanceGain and the modifiedOrder in
									///< AudioSourceAmbipanning::calculationsForAEP. Must be
									///< 0, 1 or 2.
	  // used in distanceMode 1 and 2
	static double centerRadius;
	static double oneOverCenterRadius;
	static double centerExponent;
	static double centerAttenuation;
	static double oneMinusCenterAttenuation;
	  // used in distanceMode 1
	static double dBFalloffPerUnit;
	  // used in distanceMode 2
	static double outsideCenterExponent; // = 1
    
    bool dopplerEffectEnabled;
    
    /** Will point to
        audioSourceGainEnvelope or to
        audioSourceDopplerEffect
        dependant of if the doppler effect is disabled or enabled.
     */
    PositionableAudioSource& audioSourceGainEnvOrDopplerFX;
	AudioSourceDopplerEffect audioSourceDopplerEffect;
	AudioSourceGainEnvelope audioSourceGainEnvelope;
	AudioSourceChannelInfo monoInfo;  // used in getNextAudioBlock(..).
	AudioSampleBuffer monoBuffer;  // used in getNextAudioBlock(..).
	
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
	bool numberOfSpeakersChanged;
	bool constantSpacialPosition;
	
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
	SpacialEnvelopePoint * previousSpacialPoint;
	SpacialEnvelopePoint * nextSpacialPoint;
	int nextSpacialPointIndex;
	Array <double> channelFactorAtPreviousSpacialPoint;
	Array <double> channelFactorAtNextSpacialPoint;
	Array <double> channelFactor;
	Array <double> previousChannelFactor; // used in getNextAudioBlock(..) if there is a
	// transition to a new envelope going on.
	Array <double> channelFactorDelta;
	Array <float*> sample;
	int numberOfRemainingSamples;
	
	CriticalSection callbackLock;
	
	JUCE_LEAK_DETECTOR (AudioSourceAmbipanning);
};


#endif   // __AUDIOSOURCEAMBIPANNING_HEADER__
