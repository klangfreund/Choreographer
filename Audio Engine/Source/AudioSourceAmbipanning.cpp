/*
 *  AudioSourceAmbipanning.cpp
 *  Choreographer
 *
 *  Created by sam on 100516.
 *  Copyright 2010. All rights reserved.
 *
 */

#include "AudioSourceAmbipanning.h"

AudioSourceAmbipanning::AudioSourceAmbipanning (AudioFormatReader* const audioFormatReader,
												double sampleRateOfTheAudioDevice)
    : monoBuffer (1,0),
      nextPlayPosition (-1),
      audioBlockEndPosition (-2),
      previousSpacialPoint (),
	  nextSpacialPoint (),
	  nextSpacialPointIndex (0)
{
	DBG(T("AudioSourceAmbipanning: constructor called."));
	
	// Define an initial spacial envelope.
	// It is also neccessary to set up the newSpacialEnvelope,
	// because the reallocateMemoryForTheArrays() function sets
	// newSpacialEnvelopeSet = true. (Which leads to the use
	// of newSpacialEnvelope in getNextAudioBlock(..)).
	SpacialEnvelopePoint* spacialEnvelopePoint 
	= new SpacialEnvelopePoint(0,	// time (in samples)
							   0,	// x
							   0,	// y
							   0);	// z
	newSpacialEnvelope.add(spacialEnvelopePoint);
	spacialEnvelope = newSpacialEnvelope;
	
	constantSpacialPosition = true;
	reallocateMemoryForTheArrays();
	  // this will also set newSpacialEnvelopeSet = true;
	
	audioSourceGainEnvelope = new AudioSourceGainEnvelope (audioFormatReader,
														   sampleRateOfTheAudioDevice);
}

AudioSourceAmbipanning::~AudioSourceAmbipanning()
{
	DBG(T("AudioSourceAmbipanning: destructor called."));
	delete audioSourceGainEnvelope;
}

/** Implementation of the AudioSource method. */
void AudioSourceAmbipanning::prepareToPlay (int samplesPerBlockExpected, double sampleRate)
{
	audioSourceGainEnvelope->prepareToPlay (samplesPerBlockExpected, sampleRate);
}

/** Implementation of the AudioSource method. */
void AudioSourceAmbipanning::releaseResources()
{
	audioSourceGainEnvelope->releaseResources();
}

/** Implementation of the AudioSource method. */
void AudioSourceAmbipanning::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	audioBlockEndPosition = nextPlayPosition + info.numSamples; // used here and in setNextReadPosition.
								    // It referes to the first sample after
								    // the current audio block.
	
	// only the first channel of info will be filled with audio.
	// (Since only mono sources are allowed in this application.)
	monoBuffer.setDataToReferTo(info.buffer->getArrayOfChannels(), 1, info.buffer->getNumSamples());
	monoInfo.startSample = info.startSample;
	monoInfo.numSamples = info.numSamples;
	monoInfo.buffer = &monoBuffer;
	
	audioSourceGainEnvelope->getNextAudioBlock(monoInfo);
	  // the gain envelope is now applied.
	
	// copy the samples of the first channel (with index 0) to the other channels
	for (int chan = 1; chan < info.buffer->getNumChannels(); ++chan)
	{
		info.buffer->copyFrom(chan, info.startSample, *info.buffer, 0, info.startSample, info.numSamples);
	}
	  // all channels are filled with the same mono signal - the mono source with
	  // the gain envelope applied.
	

	// This will be executed when a new spacial envelope has been set with setSpacialEnvelope(..).
	if (newSpacialEnvelopeSet)
	{
		Array<void*> oldSpacialEnvelope = spacialEnvelope;
		spacialEnvelope = newSpacialEnvelope;
		previousChannelFactor = channelFactor; // This is used in the info.buffer->applyGainRamp(..)
		// a couple of lines below to generate a smooth transition from the current spacial value to 
		// the spacial value of the new envelope.
		
		// delete content of the old spacial envelope
		for (int i = oldSpacialEnvelope.size(); --i >= 0;)
		{
			SpacialEnvelopePoint* spacialEnvelopePointToDelete = (SpacialEnvelopePoint*)oldSpacialEnvelope[i];
			delete spacialEnvelopePointToDelete;
		}
		
		if (spacialEnvelope.size() == 1) // by the way: size() == 0 can't be, this was
			// checked in setGainEnvelope(..)
		{
			constantSpacialPosition = true;
			nextSpacialPoint = (SpacialEnvelopePoint*)spacialEnvelope[0];
			double x = nextSpacialPoint->getX() * 10.0; // 1 unit in the GUI = 10 units here
			double y = nextSpacialPoint->getY() * 10.0;
			double z = nextSpacialPoint->getZ() * 10.0;
			double r; // radius, will be calculated in calculationsForAEP(..)
			double distanceGain; // will be calculated in calculationsForAEP(..)
			double modifiedOrder; // will be calculated in calculationsForAEP(..)
			
			calculationsForAEP(x, y, z, r, distanceGain, modifiedOrder);
			
			double xs, ys, zs; // speaker coordinates, used in the upcoming for-loop
			double factor;  // used in the upcoming for-loop. Only here to 
			                // make the code more readable.
			for (int channel = 0; channel < info.buffer->getNumChannels(); channel++) 
			{
				xs = ((SpeakerPosition*)positionOfSpeaker[channel])->getX();
				ys = ((SpeakerPosition*)positionOfSpeaker[channel])->getY();
				zs = ((SpeakerPosition*)positionOfSpeaker[channel])->getZ();
				
				// The ambipanning calculation
				factor = pow(0.5 + 0.5*(x*xs + y*ys + z*zs), modifiedOrder) * distanceGain;
				channelFactor.set(channel, factor);
			}
		}
		
		// if the envelope contains more than 1 point
		else
		{
			constantSpacialPosition = false;
			prepareForNewPosition(audioBlockEndPosition); // The variables are set up for the
			// next call of getNextAudioBlock(..)
		}
		
		// finally, the start and end values are prepared and the fading can be calculated.
		for (int channel = 0; channel < info.buffer->getNumChannels(); ++channel)
		{
			info.buffer->applyGainRamp(channel, 
									   info.startSample, 
									   info.numSamples, 
									   previousChannelFactor[channel], 
									   channelFactor[channel]);
		}
		newSpacialEnvelopeSet = false;
	}
	
	// This is the regular case
	else
	{	
		// If there is only one point in the spacial envelope
		if (constantSpacialPosition)
		{
			for (int channel = 0; channel < info.buffer->getNumChannels(); ++channel)
			{
				info.buffer->applyGain(channel, info.startSample, info.numSamples, channelFactor[channel]);
				  // arguments
				  //    channel = channel
				  //    startSample = info.startSample
				  //    numSamples = info.numSamples
				  //    gain = channelFactor[channel]
			}
		}
		
		// If there are multiple points in the gain envelope
		else
		{		
			currentPosition = nextPlayPosition;
			
			for (int channel = 0; channel < info.buffer->getNumChannels(); channel++) 
			{
				// Points to the first sample in the audio block.
				sample.set(channel, info.buffer->getSampleData(channel, info.startSample)); 
				  // First argument: channelNumber = channel
				  // Second argument: sampleOffset = info.startSample
			}				
				
			while (true)
			{
				// if the next spacial point is outside of the current audio block
				// (audioBlockEndPosition is the position of to the first sample
				//  after the current block)
				if (nextSpacialPoint->getPosition() >= audioBlockEndPosition )
				{
					numberOfRemainingSamples = audioBlockEndPosition - currentPosition;
					while (--numberOfRemainingSamples >= 0)
					{
						for (int channel = 0; channel < info.buffer->getNumChannels(); channel++) 
						{
							*sample[channel] *= channelFactor[channel];
							sample.set(channel, sample[channel] + 1);
							channelFactor.set(channel, channelFactor[channel] + channelFactorDelta[channel]);
						}
					}
					break;
				}
				
				// if the next gain point is inside the current audio block
				else
				{
					// apply the gain envelope up to the sample before the nextGainPoint
					numberOfRemainingSamples = nextSpacialPoint->getPosition() - currentPosition;
					while (--numberOfRemainingSamples >= 0)
					{
						for (int channel = 0; channel < info.buffer->getNumChannels(); channel++) 
						{
							*sample[channel] *= channelFactor[channel];
							sample.set(channel, sample[channel] + 1);
							channelFactor.set(channel, channelFactor[channel] + channelFactorDelta[channel]);
						}
					}
					
					// apply the gain to the sample at the nextGainPoint position					
					for (int channel = 0; channel < info.buffer->getNumChannels(); channel++) 
					{
						channelFactor.set(channel, channelFactorAtNextSpacialPoint[channel]);
						*sample[channel] *= channelFactor[channel];
						sample.set(channel, sample[channel] + 1);
					}
					
					currentPosition = nextSpacialPoint->getPosition() + 1;
				    // currentPosition tells you the next sample to apply the gain
					
					previousSpacialPoint = nextSpacialPoint;
					nextSpacialPointIndex++;
					nextSpacialPoint = (SpacialEnvelopePoint*)spacialEnvelope[nextSpacialPointIndex];
					
					// figure out the channelFactorAtPreviousSpacialPoint
					channelFactorAtPreviousSpacialPoint = channelFactorAtNextSpacialPoint;
					
					// figure out the channelFactorAtNextSpacialPoint, channelFactorDelta and channelFactor
					double xn = nextSpacialPoint->getX();
					double yn = nextSpacialPoint->getY();
					double zn = nextSpacialPoint->getZ();
					double rn; // radius, will be calculated in calculationsForAEP(..)
					double distanceGainN; // will be calculated in calculationsForAEP(..)
					double modifiedOrderN; // will be calculated in calculationsForAEP(..)	
					calculationsForAEP(xn, yn, zn, rn, distanceGainN, modifiedOrderN);
					
					double xs, ys, zs; // speaker coordinates, used in the upcoming for-loop
					double factor;  // used in the upcoming for-loop
					
					int distance = nextSpacialPoint->getPosition() - previousSpacialPoint->getPosition();
					
					for (int channel = 0; channel < info.buffer->getNumChannels(); channel++) 
					{
						// calculate the values of the float-array channelFactorAtNextSpacialPoint
						xs = ((SpeakerPosition*)positionOfSpeaker[channel])->getX();
						ys = ((SpeakerPosition*)positionOfSpeaker[channel])->getY();
						zs = ((SpeakerPosition*)positionOfSpeaker[channel])->getZ();
						factor = pow(0.5 + 0.5*(xn*xs + yn*ys + zn*zs), modifiedOrderN) * distanceGainN;
						channelFactorAtNextSpacialPoint.set(channel, factor);
						
						// calculate the values of the float-array channelFactorDelta
						channelFactorDelta.set(channel, (channelFactorAtNextSpacialPoint[channel] 
														 - channelFactorAtPreviousSpacialPoint[channel])/distance);
						
						// calculate the values of the float-array channelFactor
						channelFactor.set(channel, channelFactor[channel] + channelFactorDelta[channel]);
						// this is the gainValue for the sample of channel i at position newPosition
					}
				}
			}			
		}
	}	
}

/** Implements the PositionableAudioSource method. */
void AudioSourceAmbipanning::setNextReadPosition (int64 newPosition)
{
	// if the newPosition is not at the expected position, right after the end
	// of the last audio block
	if (audioBlockEndPosition != newPosition && !constantSpacialPosition)
	{
		DBG(T("AudioSourceAmbipanning.setNextReadPosition: newPosition = ") + String(newPosition));
		DBG(T("AudioSourceAmbipanning.setNextReadPosition: expected newPosition: ") 
			+ String(audioBlockEndPosition));
		
		// figure out between which audioEnvelopePoints we are right now
		// and set up all variables needed by getNextAudioBlock(..)
		prepareForNewPosition(newPosition);	
	}
	
	nextPlayPosition = newPosition;		
	audioSourceGainEnvelope->setNextReadPosition (newPosition);
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceAmbipanning::getNextReadPosition () const
{
	return audioSourceGainEnvelope->getNextReadPosition();
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceAmbipanning::getTotalLength () const
{
	return audioSourceGainEnvelope->getTotalLength();
}

/** Implements the PositionableAudioSource method. */
bool AudioSourceAmbipanning::isLooping () const
{
	return audioSourceGainEnvelope->isLooping();
}

void AudioSourceAmbipanning::setGainEnvelope (Array<void*> newGainEnvelope)
{
	audioSourceGainEnvelope->setGainEnvelope(newGainEnvelope);
}

void AudioSourceAmbipanning::setSpacialEnvelope(Array<void*> newSpacialEnvelope_)
{
	DBG(T("AudioSourceAmbipanning: setSpacialEnvelope called"));
	
	if (newSpacialEnvelope_.size() != 0)
	{
		// this Array must be sorted for the code in getNextAudioLoop(..)
		// to work.
		newSpacialEnvelope_.sort(spacialEnvelopePointComparator);
			
		newSpacialEnvelope = newSpacialEnvelope_;
		newSpacialEnvelopeSet = true; // when set, the spacial value 
		// is faded from the old spacial envelope to the new one, in 
		// the interval of one audio block in the getNextAudioBlock(..).
	}
	else
	{
		DBG(T("AudioSourceAmbipanning: The newSpacialEnvelope is empty! The spacial envelope hasn't been changed."));
	}
}

void AudioSourceAmbipanning::reallocateMemoryForTheArrays ()
{
	int size = channelFactorAtPreviousSpacialPoint.size();
	int numberOfNewElements = jmax(numberOfSpeakers - size, 0);
	channelFactorAtPreviousSpacialPoint.insertMultiple(size - 1, 0.0, numberOfNewElements);
	channelFactorAtNextSpacialPoint.insertMultiple(size - 1, 0.0, numberOfNewElements);
	channelFactor.insertMultiple(size - 1, 0.0, numberOfNewElements);
	previousChannelFactor.insertMultiple(size - 1, 0.0, numberOfNewElements);
	channelFactorDelta.insertMultiple(size - 1, 0.0, numberOfNewElements);
	  // arguments:
	  //  indexToInsertAt         = size - 1
	  //  newElement              = 0.0
	  //  numberOfTimesToInsertIt = numberOfNewElements
	sample.insertMultiple(size - 1, 0, numberOfNewElements);
	
	newSpacialEnvelopeSet = true; // Even thought not exactly a true statement, this enforces 
	  // getNextAudioBlock(..) to refill the arrays
}

// ------------ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/   ------------
// ATTENTION! "static void ..." would be wrong here in the definition (put it only in the declaration)!.
//  See "Prata - C++ primer", p.583

void AudioSourceAmbipanning::setOrder( int order_)
{
	order = order_;
}

void AudioSourceAmbipanning::setNumberOfSpeakers(int numberOfSpeakers_)
{
	numberOfSpeakers = numberOfSpeakers_;
}

void AudioSourceAmbipanning::setPositionOfSpeakers(Array<void*> positionOfSpeaker_)
{
	positionOfSpeaker = positionOfSpeaker_;
}

void AudioSourceAmbipanning::setDistanceModeTo0()
{
	distanceMode = 0;
}

void AudioSourceAmbipanning::setDistanceModeTo1(double centerRadius_, 
												double centerExponent_,
												double centerAttenuation_,
												double dBFalloffPerUnit_)
{
	distanceMode = 1;
	
	centerRadius = centerRadius_;
	oneOverCenterRadius = 1.0 / centerRadius;
	centerExponent = centerExponent_;
	centerAttenuation = centerAttenuation_;
	oneMinusCenterAttenuation = 1.0 - centerAttenuation;
	dBFalloffPerUnit = dBFalloffPerUnit_;
}

void AudioSourceAmbipanning::setDistanceModeTo2(double centerRadius_, 
												double centerExponent_,
												double centerAttenuation_,
												double outsideCenterExponent_)
{
	distanceMode = 2;
	
	centerRadius = centerRadius_;
	oneOverCenterRadius = 1.0 / centerRadius;
	centerExponent = centerExponent_;
	centerAttenuation = centerAttenuation_;
	oneMinusCenterAttenuation = 1.0 - centerAttenuation;
	outsideCenterExponent = outsideCenterExponent_;
}

inline void AudioSourceAmbipanning::prepareForNewPosition(int newPosition)
{
	// figure out between which audioEnvelopePoints we are right now
	// and set up all variables needed by getNextAudioBlock(..)
	nextSpacialPointIndex = 1; // since the first audioEnvelopePoint has to be at position 0 
	while (((SpacialEnvelopePoint*)spacialEnvelope[nextSpacialPointIndex])->getPosition() <= newPosition)
	{
		nextSpacialPointIndex++;
	}
	
	previousSpacialPoint = (SpacialEnvelopePoint*)spacialEnvelope[nextSpacialPointIndex - 1];
	nextSpacialPoint = (SpacialEnvelopePoint*)spacialEnvelope[nextSpacialPointIndex];
	
	// calculate the values of the float-arrays channelFactorAtPreviousSpacialPoint,
	// channelFactorAtNextSpacialPoint, channelFactorDelta and channelFactor
	double xp = previousSpacialPoint->getX();
	double yp = previousSpacialPoint->getY();
	double zp = previousSpacialPoint->getZ();
	double rp; // radius, will be calculated in calculationsForAEP(..)
	double distanceGainP; // will be calculated in calculationsForAEP(..)
	double modifiedOrderP; // will be calculated in calculationsForAEP(..)	
	calculationsForAEP(xp, yp, zp, rp, distanceGainP, modifiedOrderP);
	
	double xn = nextSpacialPoint->getX();
	double yn = nextSpacialPoint->getY();
	double zn = nextSpacialPoint->getZ();
	double rn; // radius, will be calculated in calculationsForAEP(..)
	double distanceGainN; // will be calculated in calculationsForAEP(..)
	double modifiedOrderN; // will be calculated in calculationsForAEP(..)	
	calculationsForAEP(xn, yn, zn, rn, distanceGainN, modifiedOrderN);
		
	double xs, ys, zs; // speaker coordinates, used in the upcoming for-loop
	double factor;  // used in the upcoming for-loop
	
	int distance = nextSpacialPoint->getPosition() - previousSpacialPoint->getPosition();
	int distanceFromPreviousSpacialPointPosToCurrentPos = newPosition 
							      - previousSpacialPoint->getPosition();

	for (int channel = 0; channel < numberOfSpeakers; channel++) 
	{
		// calculate the values of the float-array channelFactorAtPreviousSpacialPoint
		xs = ((SpeakerPosition*)positionOfSpeaker[channel])->getX();
		ys = ((SpeakerPosition*)positionOfSpeaker[channel])->getY();
		zs = ((SpeakerPosition*)positionOfSpeaker[channel])->getZ();
		factor = pow(0.5 + 0.5*(xp*xs + yp*ys + zp*zs), modifiedOrderP) * distanceGainP;
		channelFactorAtPreviousSpacialPoint.set(channel, factor);
		
		// calculate the values of the float-array channelFactorAtNextSpacialPoint
		factor = pow(0.5 + 0.5*(xn*xs + yn*ys + zn*zs), modifiedOrderN) * distanceGainN;
		channelFactorAtNextSpacialPoint.set(channel, factor);
		
		// calculate the values of the float-array channelFactorDelta
		channelFactorDelta.set(channel, (channelFactorAtNextSpacialPoint[channel] 
						 - channelFactorAtPreviousSpacialPoint[channel])/distance);
		
		// calculate the values of the float-array channelFactor
		channelFactor.set(channel, channelFactorAtPreviousSpacialPoint[channel]
						           + channelFactorDelta[channel]*(double)distanceFromPreviousSpacialPointPosToCurrentPos);
		  // this is the gainValue for the sample of channel i at position newPosition
	}
}

inline void AudioSourceAmbipanning::calculationsForAEP (double & x, double & y, double & z, double & r,
							double & distanceGain, double & modifiedOrder)
{
	r = sqrt(x*x + y*y + z*z); // radius, i.e. the distance of (x,y,z) to (0,0,0)
	
	// normalize x, y and z, such that they describe the projection to the unit sphere
	if (r > 0.0)
	{
		double oneOverR = 1.0 / r;
		x = x*oneOverR;
		y = y*oneOverR;
		z = z*oneOverR;
	}
	
	// \/ \/ \/ distanceGain and modifiedOrder calculation \/ \/ \/
	
	// if the position is inside the center zone
	if (r < centerRadius)
	{
		if (distanceMode == 0)
		{
			distanceGain = 1.0;
			modifiedOrder = (double)order;
		}
		else if (distanceMode == 1 || distanceMode == 2)
		{
			distanceGain = pow(r * oneOverCenterRadius, centerExponent) * oneMinusCenterAttenuation + centerAttenuation;
			
			// calculate order decrease within center_size: 
			// goes from order to 0
			modifiedOrder = (double)order * r * oneOverCenterRadius;
		}
	}
	// if the position is outside the center zone
	else
	{
		// distanceMode 0: distance doesn't have an influence on the gain
		if (distanceMode == 0)
		{
			distanceGain = 1.0;
		}
		// distanceMode 1: exponential decrease
		else if (distanceMode == 1)
		{
			distanceGain = pow( 10.0, (r - centerRadius)*dBFalloffPerUnit*0.05);
			// in the max external it is: pow(10, (dist - x->s_center_size) * x->s_source[idx]->dbunit * 0.05);
		}
		// distanceMode 2: inverse proportional decrease
		else if (distanceMode == 2)
		{
			distanceGain = pow(r - centerRadius + 1, -outsideCenterExponent);
			// in the max external it is: pow((dist + x->s_center_size3), -x->s_source[idx]->dist_att);
		}
		modifiedOrder = (double)order;
	}
	
}


// Initialisation (and memory allocation) of the static variables
// (I'm not 100% sure if this is the right place to do it)
int AudioSourceAmbipanning::order = 1;
int AudioSourceAmbipanning::numberOfSpeakers = 1;
Array<void*> AudioSourceAmbipanning::positionOfSpeaker;
	
int AudioSourceAmbipanning::distanceMode = 1;
double AudioSourceAmbipanning::centerRadius = 1.0;
double AudioSourceAmbipanning::oneOverCenterRadius = 1.0 / AudioSourceAmbipanning::centerRadius;
double AudioSourceAmbipanning::centerExponent = 1.0;
double AudioSourceAmbipanning::centerAttenuation = 0.5;
double AudioSourceAmbipanning::oneMinusCenterAttenuation = 1.0 - AudioSourceAmbipanning::centerAttenuation;
double AudioSourceAmbipanning::dBFalloffPerUnit = -3.0; // dB
double AudioSourceAmbipanning::outsideCenterExponent = 1.0;
