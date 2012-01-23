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
z (0.0),
distanceDelay (0.0)
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
    calculateTheDistanceDelayToOrigin();
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
    calculateTheDistanceDelayToOrigin();
}

void SpacialEnvelopePoint::setY(const double & y_)
{
    y = y_;
    calculateTheDistanceDelayToOrigin();
}

void SpacialEnvelopePoint::setZ(const double & z_)
{
    z = z_;
    calculateTheDistanceDelayToOrigin();
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
    calculateTheDistanceDelayToOrigin();
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
const double& SpacialEnvelopePoint::getX()
{
    return x;
}

/** Gets the spacial y-coordinate.
 @return The spacial y-coordinate.
 */
const double& SpacialEnvelopePoint::getY()
{
    return y;
}

/** Gets the spacial z-coordinate.
 @return The spacial z-coordinate.
 */
const double& SpacialEnvelopePoint::getZ()
{
    return z;
}

const double & SpacialEnvelopePoint::getDistanceDelay()
{
    return distanceDelay;
}

void SpacialEnvelopePoint::calculateTheDistanceDelayToOrigin()
{
    double distance = sqrt(x*x + y*y + z*z); // in meters
    // speed of sound = 343.2 m/s
    const double oneOverSpeedOfSound = 1.0 / 343.2;
    distanceDelay = distance * oneOverSpeedOfSound;
    // TEMP
    distanceDelay = distance * oneOverSpeedOfSound * 100;

}