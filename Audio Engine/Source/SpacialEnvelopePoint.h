/*
 *  SpacialEnvelopePoint.h
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __SPACIALENVELOPEPOINT_HEADER__
#define __SPACIALENVELOPEPOINT_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"

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
    SpacialEnvelopePoint();
    
    
    /** Constructor with a non-trivial initialisation. */
    SpacialEnvelopePoint(const int& position_, 
                         const double& x_, 
                         const double& y_, 
                         const double& z_);
    
    /** Destructor. */
    ~SpacialEnvelopePoint();
    
    /** Sets a new position in time (in samples).*/
    void setPosition(const int& position_);
    
    /** Sets a new x-coordinate in space.*/
    void setX(const double & x_);
    
    /** Sets a new y-coordinate in space.*/
    void setY(const double & y_);
    
    /** Sets a new z-coordinate in space.*/
    void setZ(const double & z_);	
    
    /** Sets the position in time and the coordinates in space. */
    void setPositionAndValue(const int & position_,
                             const double & x_,
                             const double & y_,
                             const double & z_);
    
    /** Gets the position in time.
     @return The position in time (in samples).
     */
    const int& getPosition();
    
    /** Gets the spacial x-coordinate.
     @return The spacial x-coordinate.
     */
    const double& getX() const;
    
    /** Gets the spacial y-coordinate.
     @return The spacial y-coordinate.
     */
    const double& getY() const;
    
    /** Gets the spacial z-coordinate.
     @return The spacial z-coordinate.
     */
    const double& getZ() const;
    
    /** The assignment operator */
    SpacialEnvelopePoint & operator=(const SpacialEnvelopePoint & rhs);

	
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
	 Compares two SpacialEnvelopePoints according to their
     position in time.
     
	 @param first	The first element to compare.
	 @param second	The second element to compare.
     
	 @return	<ul>	
     <li> -1, if (first.getPosition() < second.getPosition()).
     <li> 0, if (first.getPosition() = second.getPosition()).
     <li> 1, if (first.getPosition() > second.getPosition()).
     </ul>
	 */
	int compareElements (SpacialEnvelopePoint first, 
                         SpacialEnvelopePoint second) const
	{
		if (first.getPosition() < second.getPosition())
		{
			return -1;
		}
		else if (first.getPosition() > second.getPosition())
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
 This comparator is needed for the sort function of AudioSourceDopplerEffect::newSpacialEnvelope.
 The sort function is called in SpacialEnvelopePointPointerComparator::setSpacialEnvelope.
 */
class JUCE_API SpacialEnvelopePointPointerComparator
{
public:
	/** Constructor. */
	SpacialEnvelopePointPointerComparator ()
	{
	}
	
	/**
	 Compares two SpacialEnvelopePoint Pointers according to their
     position in time.
     
	 @param first	The first element to compare.
	 @param second	The second element to compare.
     
	 @return	<ul>	
     <li> -1, if (first->getPosition() < second->getPosition()).
     <li> 0, if (first->getPosition() = second->getPosition()).
     <li> 1, if (first->getPosition() > second->getPosition()).
     </ul>
	 */
	int compareElements (SpacialEnvelopePoint * first, 
                         SpacialEnvelopePoint * second) const
	{
		if (first->getPosition() < second->getPosition())
		{
			return -1;
		}
		else if (first->getPosition() > second->getPosition())
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	
private:
	JUCE_LEAK_DETECTOR (SpacialEnvelopePointPointerComparator);
};

#endif   // __SPACIALENVELOPEPOINT_HEADER__
