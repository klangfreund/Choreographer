/*
 *  SpacialEnvelopePoint.h
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 120403.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __SPACIALPOSITION_HEADER__
#define __SPACIALPOSITION_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"

/** Defines a position in space.
 
 Used by AudioSourceDopplerEffect and by AudioSourceLowPassFilter.
 */
struct SpacialPosition
{
    /** x coordinate in space. */
    double x;
    double y;
    double z;
    
    /** Constructor */
    SpacialPosition ()
    : x (0.0),
      y (0.0),
      z (0.0)
    {
    }
    
    /** Constructor */
    SpacialPosition (double x_, double y_, double z_)
    : x (x_),
    y (y_),
    z (z_)
    {
    }
    
    /** Constructor */
    SpacialPosition (const SpacialEnvelopePoint & spacialEnvPoint)
    : x (spacialEnvPoint.getX()),
      y (spacialEnvPoint.getY()),
      z (spacialEnvPoint.getZ())
    {
    }
    
    /** Returns the delay time (in seconds), measured from this spacial position
     (x,y,z) to the origin (0,0,0). */
    double getDelay()
    {
        return unitScaleFactor * sqrt(*this * *this) * oneOverSpeedOfSound;
    }
 
    /** Returns the distance, measured from this spacial position
     (x,y,z) to the origin (0,0,0). */
    double getDistance()
    {
        return sqrt(*this * *this);
    }
    
    
    static void setUnitScaleFactor(double unitScaleFactor_)
    {
        unitScaleFactor = unitScaleFactor_;
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
        return result;
    }
    
    SpacialPosition operator+ (const SpacialPosition & other) const
    {
        SpacialPosition result = *this;
        result.x += other.x;
        result.y += other.y;
        result.z += other.z;
        return result;
    }
    
    SpacialPosition operator- (const SpacialPosition & other) const
    {
        SpacialPosition result = *this;
        result.x -= other.x;
        result.y -= other.y;
        result.z -= other.z;
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
        return result;
    }
    
    /** The product with a scalar on the left hand side. */
    friend SpacialPosition operator*(double scalar, const SpacialPosition & rhs)
    {return rhs * scalar;}
    
private:
    /** The constant value of 1/(speed of sound) in meters per second. */
    // Initialized in the file AudioSourceDopplerEffect.cpp.
    static const double oneOverSpeedOfSound; // = 1.0/340.0 = = 0.00294 m/s
    
    static double unitScaleFactor; // = 1000.0, set in the cpp file.
    
};

#endif   // __SPACIALPOSITION_HEADER__
