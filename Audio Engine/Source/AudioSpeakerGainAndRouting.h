/*
 *  AudioRegionMixer.h
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 101014.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __AUDIOSPEAKERGAINANDROUTING_HEADER__
#define __AUDIOSPEAKERGAINANDROUTING_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "AudioRegionMixer.h"
#include "AudioSourceAmbipanning.h"  // To get access to the SpeakerPosition class
#include "PinkNoiseGeneratorAudioSource.h"


//==============================================================================
/**
 Contains the AEP audio channel settings.
 */
struct JUCE_API aepChannelSettings
{
	/** The gain of the AEP channel.
	 */
	double gain;
	
	/** Engages the solo.
	 
	 It is allowed to have solo activated on multiple AEP
	 channels at the same time.
	 */
	bool solo;
	
	/** Engages the mute.
	 */
	bool mute;
	
	/** Activates the pink noise generator on this AEP channel.
	 */
	bool activatePinkNoise;
	
	/** Specifies the speaker position in space in cartesian coordinates.
	 */
	SpeakerPosition speakerPosition;
	
	/** Enables the measurement of the samples that are sent to
	 the audio driver.
	 
	 The measured values are measuredRootMeanSquareValue and
	 measuredPeakValue.
	 */
	bool enableOutputMeasurement;
	
	/** Resets the peak value (which is written to measuredPeakValue),
	 that is measured on the output sample stream.
	 */
	bool resetPeakValue;
	
	/** If enableOutputMeasurement is set, the root mean square
	 with a fall off is stored in this variable.
	 
	 Measured are the samples that are sent to the audio driver.
	 */
	double measuredRootMeanSquareValue;

	/** If enableOutputMeasurement is set, the peak value is 
	 stored in this variable.
	 
	 Measured are the samples that are sent to the audio driver.
	 */
	double measuredPeakValue;
};

//==============================================================================
/**
 Represents a connection between an AEP audio channel and a physical
 output of the audio hardware. This is actually just a pair of numbers.
 */
struct JUCE_API  aepChannelHardwareOutputPair
{	
    /** 
	 The AEP audio channel.
     */
    int aepChannel;
	
    /**
	 The (physical) hardware output channel
     */
    int hardwareOutputChannel;
};

/**
 Represents a connection between an AEP audio channel and a physical
 output of the audio hardware. This is actually just a pair of numbers.
 */
class JUCE_API  AEPChannelHardwareOutputPairs
{
public:
	AEPChannelHardwareOutputPairs()
	: pairs()
	{
	}
	
	~AEPChannelHardwareOutputPairs()
	{
		for (int i=0; i<pairs.size(); i++)
		{
			delete pairs[i];
		}
	}
	
	
	/**
	 Deletes the (AEP channel, hardware output channel)-pair
	 from the array pairs, if it contains the given AEP channel.
	 Since an AEP channel can have at most one connection,
	 there is at most one pair, that can be removed.
	 */
	void deletePairIfItContainsAEPChannel(int aepChannel)
	{
		for (int i=0; i<pairs.size(); i++) 
		{
			if (pairs[i]->aepChannel == aepChannel)
			// A pair that contains the given aepChannel was found.
			{
				aepChannelHardwareOutputPair* theRemovedPair;
				theRemovedPair = pairs.remove(i);
				delete theRemovedPair;
				return;
			}
		}
	}
	
	/**
	 Deletes the (AEP channel, hardware output channel)-pair from
	 the array pairs, if it contains the given hardware output channel.
	 Since a hardware output channel can have at most one connection,
	 there is at most one pair, that can be removed.
	 */
	void deletePairIfItContainsHardwareOutputChannel(int hardwareOutputChannel)
	{
		for (int i=0; i<pairs.size(); i++) 
		{
			if (pairs[i]->hardwareOutputChannel == hardwareOutputChannel)
			// A pair that contains the given aepChannel was found.
			{
				aepChannelHardwareOutputPair* theRemovedPair;
				theRemovedPair = pairs.remove(i);
				delete theRemovedPair;
				return;
			}
		}
	}
	
	/**
	 Generates the pair (aepChannel, hardwareOutputChannel). A pointer to
	 this pair is added to the internal array (called pairs).
	 This internal array is ordered according to the second value of
	 the pairs.
	 */
	void add(int aepChannel, int hardwareOutputChannel)
	{
		deletePairIfItContainsAEPChannel(aepChannel);
		deletePairIfItContainsHardwareOutputChannel(hardwareOutputChannel);
		
		aepChannelHardwareOutputPair* newPair = new aepChannelHardwareOutputPair;
		newPair->aepChannel = aepChannel;
		newPair->hardwareOutputChannel = hardwareOutputChannel;
		
		if (pairs.size() == 0)
			// if the array pairs is empty.
		{
			pairs.add(newPair);
			return;
		}
//		if (hardwareOutputChannel < pairs[0]->hardwareOutputChannel)
//			// if the new pair has the smallest hardwareOutputChennel,
//			// it will be the new leading element.
//		{
//			pairs.insert(0, newPair);
//			return;
//		}
		int i = 0;
		while (i < pairs.size())
		{
			if (hardwareOutputChannel < pairs[i]->hardwareOutputChannel)
			{
				break;
			}
			i++;
		}
		// either pairs[i-1].hardwareOutputChannel <= hardwareOutputChannel < 
	    // pairs[i].hardwareOutputChannel, or i-1 is the index of the last
		// pair in the array pairs and newPair will be the new last pair in
		// pairs.
		pairs.insert(i, newPair);
	}
	
	/** Returns true if the given AEP channel number is part of a pair.	 
	 */
	bool containsAEPChannel(int aepChannel)
	{
		for (int i=0; i<pairs.size(); i++) 
		{
			if (pairs[i]->aepChannel == aepChannel) 
			{
				return true;
			}
		}
		return false;
	}
	
	/** Returns true if the given hardware device channel number is part of a pair.	 
	 */
	bool containsHardwareOutputChannel(int hardwareOutputChannel)
	{
		for (int i=0; i<pairs.size(); i++) 
		{
			if (pairs[i]->hardwareOutputChannel == hardwareOutputChannel) 
			{
				return true;
			}
		}
		return false;
	}
	
	int size()
	{
		return pairs.size();
	}
	
	void clear()
	{
		pairs.clear();
	}
	
	int getAepChannel(int positionOfPairInArray)
	{
		return pairs[positionOfPairInArray]->aepChannel;
	}
	
private:
	Array<aepChannelHardwareOutputPair*> pairs;
};
	

//==============================================================================
//==============================================================================
/**
 A PositionableAudioSource that ...
 
 TODO
 */
class JUCE_API  AudioSpeakerGainAndRouting  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Constructor: Creates an AudioSpeakerGainAndRouting.
	 */
	AudioSpeakerGainAndRouting();
    AudioSpeakerGainAndRouting(AudioDeviceManager* audioDeviceManager_);
	
    /** Destructor. */
    ~AudioSpeakerGainAndRouting();
    
		
    //==============================================================================
    /** Sets the AudioSource that is being used as the input source.
	 
	 The source passed in will not be deleted by this object, so must be managed by
	 the caller.
	 
	 @param newSource             The new input source to use. This might be zero.
	 */
    void setSource (AudioRegionMixer* const newAudioRegionMixer);
	
	/** Sets the AudioDeviceManager.
	 
	 Thanks to the knowledge of the AudioDeviceManager, the AudioSpeakerGainAndRouting
	 can activate and deactivate hardware output channels.
	 */
	void setAudioDeviceManager(AudioDeviceManager* audioDeviceManager_);

	/** Get the number of aep channels with a speaker configuration assigned
	 to them (by setSpeakerPosition).
	 */	
	int getNumberOfAepChannels();
	
	/**
	 Returns the number of output channels of the current
	 AudioIODevice.
	 
	 @return The number of output channels.
	 */
	int getNumberOfHardwareOutputChannels();
	
	/** Adds a new AEP channel to the array of AEP channels.
	 
	 If the specified channel has already been added, this operation aborts.	 
	 If n := aepChannel and m := array.size < n, then n-m additional channels
	 between the m'th channel and the n'th channel are added with the initial
	 values [gain = 1.0, solo = FALSE, mute = FALSE, activatePinkNoise = FALSE,
	 x = 0.0, y = 1.0, z = 0.0]
	 */
	bool addAepChannel(int aepChannel, double gain, bool solo, bool mute,
					   bool activatePinkNoise, double x, double y, double z);
	
	/** Removes an AEP channel from the array of AEP channels.
	 
	 THIS FUNCTION IS NOT YET IMPLEMENTED.
	 */
	bool removeAepChannel(int aepChannel);
	
    /** Set the speaker position for an AEP channel.
	 
	 If there are AEP channels lower than the specified aepChannel without a
	 speaker position assigned before, they get the position (1,0,0).
	 
	 @param aepChannel	The AEP channel that gets the specified speaker position.
	 @param x			The cartesian x coordinate for the speaker position.
	 @param y			The cartesian y coordinate for the speaker position.
	 @param z			The cartesian z coordinate for the speaker position.
	 */	
	bool setSpeakerPosition(int aepChannel, double x, double y, double z);
	
	/** Sets the gain of the chosen aepChannel.
	 */
	bool setGain(int aepChannel, double gain);

	/** Enables or disables the solo mode of the chosen aepChannel.
	 */
	bool setSolo(int aepChanel, bool enable);

	/** Enables or disables the mute mode of the chosen aepChannel.
	 */
	bool setMute(int aepChanel, bool enable);

	/** Enables or disables the output of pink noise on the chosen aepChannel.
	 */
	bool activatePinkNoise(int aepChanel, bool enable);
	
	/**
	 Connects an aepChannel and a hardwareDeviceChannel. Each of
	 them can participate in one connection at most. If it happens
	 that there also exist connections with the given
	 aepChannel or with the given hardwareDeviceChannel, these
	 old connections will be removed.
	 
	 To remove the connection with aepChannel, call
	 sotNewRouting(aepChannel, 0).

	 To remove the connection with hardwareOutputChannel, call
	 sotNewRouting(0, hardwareOutputChannel).
	 
	 To enable the new routing, call enableNewRouting.
	 */
	void setNewRouting(int aepChannel, int hardwareOutputChannel);

	/** Removes all connections between the AEP channels and
	 the audio hardware output channels.
	 
	To enable this routing free state, call enableNewRouting.
	*/	
	void removeAllRoutings();
	
	/** It activates the hardware channels needed for the desired
	 routing and assignes the corresponding AEP settings to them.
	 
	 Make sure the playback has been stopped before calling this.
	  
	 The resulting assignments of speaker configurations (for the 
	 active hardware channels) are transmitted to the AudioRegionMixer.
	 
	 @return	The number of active hardware output channels.
	 */
	int enableNewRouting();

	/** Removes all connections between the AEP channels and
	 the audio hardware output channels as well as all AEP
	 channels.
	 
	 Use this with care! Make sure that you have called
	 audioTransportSource.setSource (0, 0, AUDIOTRANSPORT_BUFFER);
	 before you call this method.
	 */
	void removeAllRoutingsAndAllAepChannels();
	

    //==============================================================================
    /** Implements the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);
	
    /** Implements the AudioSource method. */
    void releaseResources();
	
    /** Implements the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& info);
	
    //==============================================================================
    /** Implements the PositionableAudioSource method. */
    void setNextReadPosition (int64 newPosition);
	
    /** Implements the PositionableAudioSource method. */
    int64 getNextReadPosition() const;
	
    /** Implements the PositionableAudioSource method. */
    int64 getTotalLength() const;
	
    /** Implements the PositionableAudioSource method. 
	 
	 Comment by Sam: This kind of loop means, that the
	 source is repeated for an infinite number of time.
	 Or stated differently, at any point in time, the
	 source is producing sound, since it is looping.
	 */
    bool isLooping() const;
	
    //==============================================================================

	
private:
	/** Indicates if the given aepChannel is connected with a
	    hardware output.
	 
	 @return	Indicates if the given aepChannel is connected with
				a hardware output.
	 */
	bool aepChannelIsConnectedWithActiveHardwareChannel(int aepChannel);
	
	AudioRegionMixer* audioRegionMixer;
	
	AudioDeviceManager* audioDeviceManager;

	AEPChannelHardwareOutputPairs aepChannelHardwareOutputPairs;
			///< This object
			///  hosts an array of aepChannel - hardwareOutputChannel
			///  pairs. These pairs determine the connection between
			///  the AEP- and the hardware channels. This array of
			///  pairs is hosted here, because it is needed to determine
			///  which hardware output channels need to be activated.
	
	
	Array<aepChannelSettings*> aepChannelSettingsAscending;
	Array<aepChannelSettings*> aepChannelSettingsOrderedByActiveHardwareChannels;
	
	int numberOfMutedChannels; 
	int numberOfSoloedChannels;
	int numberOfChannelsWithActivatedPinkNoise;
	
	AudioSampleBuffer pinkNoiseBuffer;  ///< Used in getNextAudioBlock .
	AudioSourceChannelInfo pinkNoiseInfo; ///< Used in getNextAudioBlock .
	PinkNoiseGeneratorAudioSource pinkNoiseGeneratorAudioSource;
	
	CriticalSection connectionLock; ///< Used in enableNewRouting .

};


#endif   // __AUDIOSPEAKERGAINANDROUTING_HEADER__
