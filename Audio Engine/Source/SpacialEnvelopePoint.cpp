/*
 *  AudioSourceAmbipanning.cpp
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#include "SpacialEnvelopePoint.h"

SpacialEnvelopePoint::SpacialEnvelopePoint()
:   position (0),
x (0.0),
y (0.0),
z (0.0)
{
}

SpacialEnvelopePoint::SpacialEnvelopePoint(const int& position_, 
                                           const double& x_, 
                                           const double& y_, 
                                           const double& z_)
:   position (position_),
x (x_),
y (y_),
z (z_)
{
}

SpacialEnvelopePoint::~SpacialEnvelopePoint()
{
}

void SpacialEnvelopePoint::setPosition(const int& position_)
{
    position = position_;
    
}

void SpacialEnvelopePoint::setX(const double & x_)
{
    x = x_;
}

void SpacialEnvelopePoint::setY(const double & y_)
{
    y = y_;
}

void SpacialEnvelopePoint::setZ(const double & z_)
{
    z = z_;
}

/** Sets the position in time and the coordinates in space. */
void SpacialEnvelopePoint::setPositionAndValue(const int & position_,
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
const int& SpacialEnvelopePoint::getPosition()
{
    return position;
}

/** Gets the spacial x-coordinate.
 @return The spacial x-coordinate.
 */
const double& SpacialEnvelopePoint::getX() const
{
    return x;
}

/** Gets the spacial y-coordinate.
 @return The spacial y-coordinate.
 */
const double& SpacialEnvelopePoint::getY() const
{
    return y;
}

const double& SpacialEnvelopePoint::getZ() const
{
    return z;
}

SpacialEnvelopePoint & SpacialEnvelopePoint::operator=(const SpacialEnvelopePoint & rhs)
{
    // Check for self-assignment!
    if (this == &rhs)      // Same object?
        return *this;        // Yes, so skip assignment, and just return *this.
    
    position = rhs.position;
    x = rhs.x;
    y = rhs.y;
    z = rhs.z;
    
    return *this;
}
