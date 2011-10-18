/*
 *  AudioSourceAmbipanning.h
 *  Choreographer
 *
 *  Created by sam on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __AUDIOSOURCEAMBIPANNING_HEADER__
#define __AUDIOSOURCEAMBIPANNING_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "AudioSourceGainEnvelope.h"

//==============================================================================
/**
 Describes a point in space at a certain time.
 Used by AudioSourceAmbipanning::spacialEnvelope, by 
 AudioSourceAmbipanning::newSpacialEnvelope and by the argument
 newSpacialEnvelope of AudioSourceAmbipanning::setSpacialEnvelope.
 */
class JUCE_API  SpacialEnvelopePoint
{
public:
    /** Default constructor. Sets SpacialEnvelopePoint::position = 0,
     SpacialEnvelopePoint::x = 0.0, SpacialEnvelopePoint::y = 0.0,
     SpacialEnvelopePoint::z = 0.0.
     */
    SpacialEnvelopePoint()
    : position (0),
      x (0.0),
      y (0.0),
      z (0.0)
    {
    }
    
    
    /** Constructor with a non-trivial initialisation. */
    SpacialEnvelopePoint(int position_, double x_, double y_, double z_)
    : position (position_),
    x (x_),
    y (y_),
    z (z_)
    {
        }
    
    /** Destructor. */
    ~SpacialEnvelopePoint()
    {
    }
    
    /** Sets a new position in time (in samples).*/
    void setPosition(const int& position_)
    {
    	position = position_;
    	
    }
    
    /** Sets a new x-coordinate in space.*/
    void setX(const double & x_)
    {
    	x = x_;
    }
    
    /** Sets a new y-coordinate in space.*/
    void setY(const double & y_)
    {
    	y = y_;
    }
    
    /** Sets a new z-coordinate in space.*/
    void setZ(const double & z_)
    {
    	z = z_;
    }	
    
    /** Sets the position in time and the coordinates in space. */
    void setPositionAndValue(const int & position_,
    			 const double & x_,
    			 const double & y_,
    			 const double & z_)
    {
    	position = position_;
    	x = x_;
    	y = y_;
    	z = z_;
    }
    
    /** Gets the position in time.
     @return The position in time (in samples).
     */
    int getPosition()
    {
    	return position;
    }
    
    /** Gets the spacial x-coordinate.
     @return The spacial x-coordinate.
     */
    double getX()
    {
    	return x;
    }
    
    /** Gets the spacial y-coordinate.
     @return The spacial y-coordinate.
     */
    double getY()
    {
    	return y;
    }
    
    /** Gets the spacial z-coordinate.
     @return The spacial z-coordinate.
     */
    double getZ()
    {
    	return z;
    }
	
private:	
    /** The position in time (in samples). */
    int position;
	
    /** The x-coordinate in space. */
    double x;

    /** The y-coordinate in space. */
    double y;

    /** The z-coordinate in space. */
    double z;
	
	JUCE_LEAK_DETECTOR (SpacialEnvelopePoint);
};

//==============================================================================
/**
 This comparator is needed for the sort function of AudioSourceAmbipanning::newSpacialEnvelope.
 The sort function is called in AudioSourceAmbipanning::setSpacialEnvelope.
 */
class JUCE_API SpacialEnvelopePointComparator
{
public:
	/** Constructor. */
	SpacialEnvelopePointComparator ()
	{
	}
	
	/**
	 Compares two elements of type void*, that are actually pointers
	 to SpacialEnvelopePoint after typecasting.

	 @param first	The first element to compare.
	 @param second	The second element to compare.

	 @return	<ul>	
	 		<li> -1, if ((SpacialEnvelopePoint*)first)->getPosition() 
	 		    < ((SpacialEnvelopePoint*)second)->getPosition().
			<li> 0, if ((SpacialEnvelopePoint*)first)->getPosition() 
	 		    = ((SpacialEnvelopePoint*)second)->getPosition().
			<li> 1, if ((SpacialEnvelopePoint*)first)->getPosition() 
		    	    > ((SpacialEnvelopePoint*)second)->getPosition().
			</ul>
	 */
	int compareElements (void* first, void* second) const
	{
		if (((SpacialEnvelopePoint*)first)->getPosition() < ((SpacialEnvelopePoint*)second)->getPosition())
		{
			return -1;
		}
		else if (((SpacialEnvelopePoint*)first)->getPosition() > ((SpacialEnvelopePoint*)second)->getPosition())
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	
private:
	JUCE_LEAK_DETECTOR (SpacialEnvelopePointComparator);
};

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
	SpeakerPosition (double x_, double y_, double z_);
    
    SpeakerPosition (const SpeakerPosition& other);
	
	/** Destructor. */
	~SpeakerPosition ();
    
    /** The assignment operator.
     
     @param other   The source object from the right hand side.
     @return        This object to allow a=b=c like semantics.
     */
    const SpeakerPosition& operator= (const SpeakerPosition& other);
	
	/** Sets the x-coordinate in space. */
	void setX (double x_);
	
	/** Sets the y-coordinate in space. */
	void setY (double y_);
	
	/** Sets the z-coordinate in space. */
	void setZ (double z_);
	
	/** Sets the x-, y- and z-coordinate in space. */
	void setXYZ (double x_, double y_, double z_);
	
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
	 @param newGainEnvelope		it will be deleted in the setGainEnvelope(..) of
								AudioSourceGainEnvelope or in the destructor of
								AudioSourceGainEnvelope, so you don't have to
								care about.
	 */
	void setGainEnvelope (Array<void*> newGainEnvelope);

	/**
	 TODO
	 */
	void setSpacialEnvelope (Array<void*> newSpacialEnvelope);
	
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
	 Sets the number of speakers used.
	 */
	static void setNumberOfSpeakers(int numberOfSpeakers_);

	/** 
	 Sets the positions of the speakers.
	 */
	static void setPositionOfSpeakers(Array<void*> positionOfSpeaker_);

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
	 */
	inline void calculationsForAEP (double & x, double & y, double & z, double & r,
									double & distanceGain, double & modifiedOrder);
	
	static int order;
	static int numberOfSpeakers;
	static Array<void*> positionOfSpeaker; // you have to typecast elements to SpeakerPosition*
	
	// for the distance calculations
	static int distanceMode;		///< Determines which algorithm is chosen to calculate the 
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
	
	AudioSourceGainEnvelope* audioSourceGainEnvelope;
	AudioSourceChannelInfo monoInfo;  // used in getNextAudioBlock(..).
	AudioSampleBuffer monoBuffer;  // used in getNextAudioBlock(..).
	
	Array<void*> spacialEnvelope; ///< TODO

	/** This is used by AudioSourceAmbipanning::setSpacialEnvelope and
	 by AudioSourceAmbipanning::getNextAudioBlock when a new envelope is engaged.
	 */
	Array<void*> newSpacialEnvelope;

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
	SpacialEnvelopePoint* previousSpacialPoint;
	SpacialEnvelopePoint* nextSpacialPoint;
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
