/*
 *  AudioRegionMixer.cpp
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 101014.
 *  Copyright 2010. All rights reserved.
 *
 */

#include "AudioSpeakerGainAndRouting.h"

#define INITIAL_PINK_NOISE_BUFFER_SIZE 4096

//==============================================================================
AepChannelSettings::AepChannelSettings()
:   gain(0.0),
    lastGain(0.0),
    solo(false),
    mute(false),
    pinkNoise(false),
    speakerPosition(),
    measurementEnabled(false),
    measuredDecayingValue(0.0),
    measuredPeakValue(0.0)
{
}

AepChannelSettings::AepChannelSettings(const double& gain_,
                                       const SpeakerPosition& speakerPosition_)
:   gain(gain_),
    lastGain(gain_),
    solo(false),
    mute(false),
    pinkNoise(false),
    speakerPosition(speakerPosition_),
    measurementEnabled(false),
    measuredDecayingValue(0.0),
    measuredPeakValue(0.0)
{
}

AepChannelSettings::AepChannelSettings(const double& gain_,
                                       const bool& solo_,
                                       const bool& mute_,
                                       const bool& pinkNoise_,
                                       const double& x_,
                                       const double& y_,
                                       const double& z_)
:   gain(gain_),
    lastGain(gain_),
    solo(solo_),
    mute(mute_),
    pinkNoise(pinkNoise_),
    speakerPosition(x_, y_, z_),
    measurementEnabled(false),
    measuredDecayingValue(0.0),
    measuredPeakValue(0.0)
{
}

AepChannelSettings::AepChannelSettings(const AepChannelSettings& other)
:   gain(other.gain),
    lastGain(other.lastGain),
    solo(other.solo),
    mute(other.mute),
    pinkNoise(other.pinkNoise),
    speakerPosition(other.speakerPosition),
    measurementEnabled(other.measurementEnabled),
    measuredDecayingValue(other.measuredDecayingValue),
    measuredPeakValue(other.measuredPeakValue)
{
}

const AepChannelSettings& AepChannelSettings::operator=(const AepChannelSettings& other)
{
    gain = other.gain;
    lastGain = other.lastGain;
    solo = other.solo;
    mute = other.mute;
    pinkNoise = other.pinkNoise;
    speakerPosition = other.speakerPosition;
    measurementEnabled = other.measurementEnabled;
    measuredDecayingValue = other.measuredDecayingValue;
    measuredPeakValue = other.measuredPeakValue;
    
    return *this;
}

void AepChannelSettings::setGain(const double& gain_)
{
    gain = gain_;
}

void AepChannelSettings::setLastGain(const double& lastGain_)
{
    lastGain = lastGain_;
}

void AepChannelSettings::setSolo(const bool& engageSolo)
{
    solo = engageSolo;
}

void AepChannelSettings::setMute(const bool& engageMute)
{
    mute = engageMute;
}

void AepChannelSettings::activatePinkNoise(const bool& turnPinkNoiseOn)
{
    pinkNoise = turnPinkNoiseOn;
}

void AepChannelSettings::setSpeakerPosition(const SpeakerPosition& speakerPosition_)
{
    speakerPosition = speakerPosition_;
}

void AepChannelSettings::setSpeakerPosition(const double& x,
                                            const double& y,
                                            const double& z)
{
    speakerPosition.setXYZ(x, y, z);
}

void AepChannelSettings::enableMeasurement(const bool& turnMeasurementOn)
{
    measurementEnabled = turnMeasurementOn;
}

void AepChannelSettings::setMeasuredDecayingValue(const double& measurement)
{
    measuredDecayingValue = measurement;
}

void AepChannelSettings::setMeasuredPeakValue(const double& measurement)
{
    measuredPeakValue = measurement;
}

const double& AepChannelSettings::getGain()
{
    return gain;
}

const double& AepChannelSettings::getLastGain()
{
    return lastGain;
}

const bool&  AepChannelSettings::getSoloStatus()
{
    return solo;
}

const bool&  AepChannelSettings::getMuteStatus()
{
    return mute;
}

const bool&  AepChannelSettings::getPinkNoiseStatus()
{
    return pinkNoise;
}

const SpeakerPosition& AepChannelSettings::getSpeakerPosition()
{
    return speakerPosition;
}

const bool&  AepChannelSettings::getMeasurementStatus()
{
    return measurementEnabled;
}

const double& AepChannelSettings::getMeasuredDecayingValue()
{
    return measuredDecayingValue;
}

const double& AepChannelSettings::getMeasuredPeakValue()
{
    return measuredPeakValue;
}


//==============================================================================
AepChannelHardwareOutputPairs::AepChannelHardwareOutputPairs()
{
}

AepChannelHardwareOutputPairs::~AepChannelHardwareOutputPairs()
{
}

void AepChannelHardwareOutputPairs::deletePairIfItContainsAEPChannel(const int& aepChannel)
{
    for (int i=0; i<pairs.size(); i++) 
    {
        if (pairs[i].getAepChannel() == aepChannel)
			// A pair that contains the given aepChannel was found.
        {
            pairs.remove(i);
            return;
        }
    }
}

void AepChannelHardwareOutputPairs::deletePairIfItContainsHardwareOutputChannel(const int& hardwareOutputChannel)
{
    for (int i=0; i<pairs.size(); i++) 
    {
        if (pairs[i].getHardwareOutputChannel() == hardwareOutputChannel)
			// A pair that contains the given aepChannel was found.
        {
            pairs.remove(i);
            return;
        }
    }
}

void AepChannelHardwareOutputPairs::add(const int& aepChannel, const int& hardwareOutputChannel)
{
    deletePairIfItContainsAEPChannel(aepChannel);
    deletePairIfItContainsHardwareOutputChannel(hardwareOutputChannel);
    
    AepChannelHardwareOutputPair newPair = AepChannelHardwareOutputPair(aepChannel, hardwareOutputChannel);
    
    if (pairs.size() == 0)
        // if the array pairs is empty.
    {
        pairs.add(newPair);
        return;
    }
    
    int i = 0;
    while (i < pairs.size())
    {
        if (hardwareOutputChannel < pairs[i].getHardwareOutputChannel())
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

bool AepChannelHardwareOutputPairs::containsAEPChannel(const int& aepChannel)
{
    for (int i=0; i<pairs.size(); i++) 
    {
        if (pairs[i].getAepChannel() == aepChannel) 
        {
            return true;
        }
    }
    return false;
}

bool AepChannelHardwareOutputPairs::containsHardwareOutputChannel(const int& hardwareOutputChannel)
{
    for (int i=0; i<pairs.size(); i++) 
    {
        if (pairs[i].getHardwareOutputChannel() == hardwareOutputChannel) 
        {
            return true;
        }
    }
    return false;
}

int AepChannelHardwareOutputPairs::size()
{
    return pairs.size();
}

void AepChannelHardwareOutputPairs::clear()
{
    pairs.clear();
}

const int& AepChannelHardwareOutputPairs::getAepChannel(const int& positionOfPairInArray)
{
    return pairs[positionOfPairInArray].getAepChannel();
}



//==============================================================================
AudioSpeakerGainAndRouting::AudioSpeakerGainAndRouting()
: audioSource (0),
  audioRegionMixer (0),
  aepChannelHardwareOutputPairs (),
  numberOfHardwareOutputChannels (0),
  numberOfMutedChannels (0),
  numberOfSoloedChannels (0),
  numberOfChannelsWithActivatedPinkNoise (0),
  numberOfChannelsWithEnabledMeasurement (0),
  pinkNoiseGeneratorAudioSource (),
  pinkNoiseBuffer (1, INITIAL_PINK_NOISE_BUFFER_SIZE),
  positionOfSpeakers ()
{
	DBG(T("AudioSpeakerGainAndRouting: constructor (without any argument) called."));
	
	// initialize the pinkNoiseInfo
	pinkNoiseInfo.buffer = &pinkNoiseBuffer;
	pinkNoiseInfo.startSample = 0;
	pinkNoiseInfo.numSamples = 0;
}

AudioSpeakerGainAndRouting::AudioSpeakerGainAndRouting(AudioRegionMixer* audioRegionMixer_)
: audioSource (0),
  audioRegionMixer (audioRegionMixer_),
  aepChannelHardwareOutputPairs (),
  numberOfHardwareOutputChannels (0),
  numberOfMutedChannels (0),
  numberOfSoloedChannels (0),
  numberOfChannelsWithActivatedPinkNoise (0),
  numberOfChannelsWithEnabledMeasurement (0),
  pinkNoiseGeneratorAudioSource (),
  pinkNoiseBuffer (1, INITIAL_PINK_NOISE_BUFFER_SIZE),
  positionOfSpeakers ()
{
	DBG(T("AudioSpeakerGainAndRouting: constructor (with AudioDeviceManager argument) called."));
	
	// initialize the pinkNoiseInfo
	pinkNoiseInfo.buffer = &pinkNoiseBuffer;
	pinkNoiseInfo.startSample = 0;
	pinkNoiseInfo.numSamples = 0;
}

AudioSpeakerGainAndRouting::~AudioSpeakerGainAndRouting()
{
	DBG(T("AudioSpeakerGainAndRouting: destructor called."));
	
	removeAllRoutingsAndAllAepChannels();
}

void AudioSpeakerGainAndRouting::setSource (AudioSource* const newAudioSource)
{
	DBG(T("AudioSpeakerGainAndRouting: setSource called."));
	
	// sam: This part is copied from the AudioTransportSource
    if (audioSource == newAudioSource)
    {
        if (audioSource == 0)
            return;
		
        setSource (0); // deselect and reselect to avoid releasing resources wrongly
    }
	
	AudioSource* oldAudioSource = audioSource;

	audioSource = newAudioSource;
	
	if (oldAudioSource != 0) {
		oldAudioSource->releaseResources();
	}
}

int AudioSpeakerGainAndRouting::getNumberOfHardwareOutputChannels()
{
    return numberOfHardwareOutputChannels;
}

int AudioSpeakerGainAndRouting::getNumberOfAepChannels()
{
	return aepChannelSettingsOrderedByAepChannel.size();
}

bool AudioSpeakerGainAndRouting::addAepChannel(int aepChannel, double gain, bool solo, 
											   bool mute, bool activatePinkNoise, 
											   double x, double y, double z)
{
	DBG(T("AudioSpeakerGainAndRouting: addAepChannel has been called."));

	if (aepChannelSettingsOrderedByAepChannel.size() > aepChannel)
	{
		// The specified AEP channel already exists.
		DBG(T("addAepChannel can't add the AEP channel because it already exists."));
		return false;
	}
	if (aepChannel < 0)
	{
		// The specified AEP channel is too small (< 0).
		DBG(T("addAepChannel can't add the AEP channel because aepChannel is smaller than zero."));
		return false;
	}
	
	// Add missing aepChannels - if there needs to be any.
	while (aepChannelSettingsOrderedByAepChannel.size() < aepChannel)
	{
        // Add an aepChannel with the default values from its default constructor
        // (and from the def. constructor of speakerPosition).
		aepChannelSettingsOrderedByAepChannel.add(new AepChannelSettings());
	}
	
	// Add the specified AEP channel.
    aepChannelSettingsOrderedByAepChannel.add(new AepChannelSettings(gain,
                                                           solo,
                                                           mute,
                                                           activatePinkNoise,
                                                           x,
                                                           y,
                                                           z));
	
	return true;
}

bool AudioSpeakerGainAndRouting::removeAepChannel(int aepChannel)
{
	// THIS FUNCTION IS NOT YET IMPLEMENTED.
	return false;
}

bool AudioSpeakerGainAndRouting::setSpeakerPosition(int aepChannel, double x, double y, double z)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size() -1.
		return false;
	}
	aepChannelSettingsOrderedByAepChannel[aepChannel]->setSpeakerPosition(x, y, z);
    
    // Update the positionOfSpeakers and
	// let the audioRegionMixer know about the new speaker configurations.
    updateThePositionOfSpeakers();
    
	return true;
}

bool AudioSpeakerGainAndRouting::setGain(int aepChannel, double gain)
{
	DBG(T("AudioSpeakerGainAndRouting.setGain on aepChannel ") + String(aepChannel) + T(" with gain ") + String(gain));

	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size() -1.
		return false;
	}
		
	aepChannelSettingsOrderedByAepChannel[aepChannel]->setGain(gain);
	return true;
}

bool AudioSpeakerGainAndRouting::setSolo(int aepChannel, bool enable)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size() -1.
		return false;
	}
	else
	{
		const ScopedLock sl (audioSpeakerGainAndRoutingLock);
		
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfSoloedChannels wouldn't
		// be accurate)
		if (aepChannelSettingsOrderedByAepChannel[aepChannel]->getSoloStatus() != enable)
		{
			if (enable)
			{
				numberOfSoloedChannels++;
			}
			else
			{
				numberOfSoloedChannels--;
			}
			aepChannelSettingsOrderedByAepChannel[aepChannel]->setSolo(enable);
		}
		
		DBG(T("AudioSpeakerGainAndRouting: setSolo called. numberOfSoloedChannels = ") + String(numberOfSoloedChannels));

		return true;
	}
}

bool AudioSpeakerGainAndRouting::setMute(int aepChannel, bool enable)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size() -1.
		return false;
	}
	else
	{
		const ScopedLock sl (audioSpeakerGainAndRoutingLock);
		
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfMutedChannels wouldn't
		// be accurate)
		if (aepChannelSettingsOrderedByAepChannel[aepChannel]->getMuteStatus() != enable)
		{
			if (enable)
			{
				numberOfMutedChannels++;
			}
			else
			{
				numberOfMutedChannels--;
			}
			aepChannelSettingsOrderedByAepChannel[aepChannel]->setMute(enable);
		}
		return true;
	}
}

bool AudioSpeakerGainAndRouting::activatePinkNoise(int aepChannel, bool enable)
{	
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1.
		DBG(T("AudioSpeakerGainAndRouting.activatePinkNoise: the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1."));
		return false;
	}
	else
	{
		const ScopedLock sl (audioSpeakerGainAndRoutingLock);
		
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfChannelsWithActivatedPinkNoise wouldn't
		// be accurate)
		if (aepChannelSettingsOrderedByAepChannel[aepChannel]->getPinkNoiseStatus() != enable)
		{
			if (enable)
			{
				numberOfChannelsWithActivatedPinkNoise++;
			}
			else
			{
				numberOfChannelsWithActivatedPinkNoise--;
			}
			aepChannelSettingsOrderedByAepChannel[aepChannel]->activatePinkNoise(enable);
        }		
		return true;
	}
}

void AudioSpeakerGainAndRouting::setAmplitudeOfPinkNoiseGenerator(const double newAmplitude_)
{
	pinkNoiseGeneratorAudioSource.setAmplitude(newAmplitude_);
}


bool AudioSpeakerGainAndRouting::enableMeasurement(int aepChannel, bool enable)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1.
		DBG(T("AudioSpeakerGainAndRouting.setMeasurement: the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1."));
		return false;
	}
	else
	{
		const ScopedLock sl (audioSpeakerGainAndRoutingLock);
		
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfChannelsWithEnabledMeasurement wouldn't
		// be accurate)
		if (aepChannelSettingsOrderedByAepChannel[aepChannel]->getMeasurementStatus() != enable)
		{
			if (enable)
			{
				numberOfChannelsWithEnabledMeasurement++;
			}
			else
			{
				numberOfChannelsWithEnabledMeasurement--;
			}
			aepChannelSettingsOrderedByAepChannel[aepChannel]->enableMeasurement(enable);
		}
		return true;
	}
}

bool AudioSpeakerGainAndRouting::resetMeasuredPeakValue(int aepChannel)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1.
		DBG(T("AudioSpeakerGainAndRouting.resetMeasuredPeakValue: the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1."));
		return false;
	}
	else
	{
		aepChannelSettingsOrderedByAepChannel[aepChannel]->setMeasuredPeakValue(0.0);
		return true;
	}
}

float AudioSpeakerGainAndRouting::getMeasuredDecayingValue(int aepChannel)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1.
		DBG(T("AudioSpeakerGainAndRouting.resetMeasuredPeakValue: the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1."));
		return 0.0f;
	}
	else
	{
		return aepChannelSettingsOrderedByAepChannel[aepChannel]->getMeasuredDecayingValue();
	}
}

float AudioSpeakerGainAndRouting::getMeasuredPeakValue(int aepChannel)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsOrderedByAepChannel.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1.
		DBG(T("AudioSpeakerGainAndRouting.resetMeasuredPeakValue: the given AEP channel is out of the possible range 0, ..., aepChannelSettingsOrderedByAepChannel.size()-1."));
		return 0.0f;
	}
	else
	{
		return aepChannelSettingsOrderedByAepChannel[aepChannel]->getMeasuredPeakValue();
	}
}

void AudioSpeakerGainAndRouting::removeAllRoutings()
{
	aepChannelHardwareOutputPairs.clear();
}


void AudioSpeakerGainAndRouting::setNewRouting(int aepChannel, int hardwareOutputChannel)
{
	DBG(T("AudioSpeakerGainAndRouting: setNewRouting(") + String(aepChannel) + T(", ") + String(hardwareOutputChannel) + T(") called."));
	
	// check if the arguments define a valid configuration.
	if (aepChannel < 0 && hardwareOutputChannel < 0)
	{
		DBG(T("Error. Both arguments (aepChannel and hardwareOutputChannel) are smaller than zero. \
			  This is not a valid set of arguments!"));
		return;
	}
	if (aepChannel >= getNumberOfAepChannels())
	{
		DBG(T("Error. The aepChannel argument is bigger than the available AEP channels. Please configure \
			  the number of AEP channels needed by calling setSpeakerPosition the appropriate \
			  number of times before calling connectAepChannelWithHardwareOutputChannel."));
		return;
	}
    // hardwareOutputChannel >= numberOfHardwareOutputChannels
    // is allowed.

	// ... now we are sure to have a valid configuration.
	
	
	if (aepChannel < 0)
	{
		// Remove the pair with the given hardwareOutputChannel.
		aepChannelHardwareOutputPairs.deletePairIfItContainsHardwareOutputChannel(hardwareOutputChannel);
	}
	else if (hardwareOutputChannel < 0)
	{
		// Remove the pair with the given aepChannel.
		aepChannelHardwareOutputPairs.deletePairIfItContainsAEPChannel(aepChannel);
	}
	else
	{	
		// Add the pair.
		aepChannelHardwareOutputPairs.add(aepChannel, hardwareOutputChannel);
	}
}

int AudioSpeakerGainAndRouting::enableNewRouting(AudioDeviceManager *audioDeviceManager)
{	
	DBG(T("AudioSpeakerGainAndRouting: enableNewRouting called."));
	
	// This section is scope locked.
	const ScopedLock sl (connectionLock);
	
	// The numberOfHardwareOutputChannels should be already correctly set,
	// but to be on the safe side its set one more time:
	AudioIODevice* currentAudioDevice = audioDeviceManager->getCurrentAudioDevice();
		// this points to a object used by the audioDeviceManager, don't delete it!
	StringArray outputChannelNames = currentAudioDevice->getOutputChannelNames();
	numberOfHardwareOutputChannels = outputChannelNames.size();
    DBG(T("AudioSpeakerGainAndRouting::enableNewRouting: Number of hardware output channels = ") + String(numberOfHardwareOutputChannels));
	
	// Activate (and deactivate) the hardware device output channels as needed
	AudioDeviceManager::AudioDeviceSetup audioDeviceSetup;
	audioDeviceManager->getAudioDeviceSetup(audioDeviceSetup);
	
	// temp:
	DBG(T("AudioSpeakerGainAndRouting::enableNewRouting: OutputChannels (before) = ") + String(audioDeviceSetup.outputChannels.toInteger()));
	
	// Figure out which hardware outputs will be in use.
	audioDeviceSetup.outputChannels.clear();
        // outputChannels is a BigInteger. The bits on it determines the active
        // output channels.
	for (int i=0; i != numberOfHardwareOutputChannels; ++i)
	{
		if (aepChannelHardwareOutputPairs.containsHardwareOutputChannel(i))
		{
			audioDeviceSetup.outputChannels.setBit(i);
		}
		// temp:
		DBG(T("AudioSpeakerGainAndRouting::enableNewRouting: OutputChannels (set bits) = ") + String(audioDeviceSetup.outputChannels.toInteger()));
	}
	
	// temp
	AudioIODevice* audioIODevice = audioDeviceManager->getCurrentAudioDevice();
	BigInteger activeOutputChannels = audioIODevice->getActiveOutputChannels();
	int numberOfActiveOutputChannelsBefore = activeOutputChannels.countNumberOfSetBits();
	DBG(T("AudioSpeakerGainAndRouting::enableNewRouting: Number of active output channels (before) = ") + String(numberOfActiveOutputChannelsBefore));
	// end temp
	
	audioDeviceSetup.useDefaultOutputChannels = false;
		// This needs to be set. Otherwise the desired changes of the active
		// channels won't take effect.
	bool treatAsChosenDevice = true;
	String error = audioDeviceManager->setAudioDeviceSetup(audioDeviceSetup, treatAsChosenDevice);
	if (error != T(""))
	{
		DBG(T("AudioSpeakerGainAndRouting::enableNewRouting: Error message of setAudioDeviceSetup: ") + error);
	}
	
	activeOutputChannels = audioIODevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();
    
    // temp
	DBG(T("AudioSpeakerGainAndRouting::enableNewRouting: Number of active output channels (after) = ") + String(numberOfActiveOutputChannels));
	// end temp
	
	// Let the audioSpeakerGainAndRouting know about the new connections.
	// The audioSpeakerGainAndRouting will tell the audioRegionMixer
	// which speaker setting to use on which (active) hardware/buffer
	// channel.
	
	// Set the measuredDecayingValue of all used aep channels to zero.
	//   (If this would not be done, the vu bar of a disconnected aep channel
	//   would stay constant at the last measured value.
	//   This is not done for the measuredPeakValue, because that value might
	//   still be of interest.)
	for (int i=0; i < aepChannelSettingsOrderedByActiveHardwareChannels.size(); i++)
	{
		aepChannelSettingsOrderedByActiveHardwareChannels[i]->setMeasuredDecayingValue(0.0);
	}
	
	// Remove all elements from the array (which will be filled with
	// the most recent routing configuration in the following loop).
	aepChannelSettingsOrderedByActiveHardwareChannels.clear();
	
	// The pairs in aepChannelHardwareOutputPairs are in ascending order,
	// sorted by their hardware output channel values.
	// This loop fills the array aepChannelSettingsOrderedByActiveHardwareChannels.
	for (int i=0; i != numberOfActiveOutputChannels && i != aepChannelHardwareOutputPairs.size(); ++i)
	{
		// Fill the aepChannelSettingsOrderedByActiveHardwareChannels array.
		int AepChannelConnectedWithTheIthActiveHardwareOutput
		    = aepChannelHardwareOutputPairs.getAepChannel(i);
		aepChannelSettingsOrderedByActiveHardwareChannels.add(
		    aepChannelSettingsOrderedByAepChannel[AepChannelConnectedWithTheIthActiveHardwareOutput]);
	}
	
    // Update the positionOfSpeakers and
	// let the audioRegionMixer know about the new speaker configurations.
    updateThePositionOfSpeakers();
	
	// Return the number of active hardware output channels.
	return numberOfActiveOutputChannels;
}


void AudioSpeakerGainAndRouting::removeAllRoutingsAndAllAepChannels()
{
	removeAllRoutings();
	
	// Clear the AEP arrays.
    aepChannelSettingsOrderedByAepChannel.clear();
	aepChannelSettingsOrderedByActiveHardwareChannels.clear();
    aepChannelSettingsOrderedByActiveHardwareChannelsBackup.clear();	
}

int AudioSpeakerGainAndRouting::switchToBounceMode(bool bounceMode_)
{
	// Only change something, if there is something to change.
	if (bounceMode_ != bounceMode)
	{
        
		const ScopedLock sl (audioSpeakerGainAndRoutingLock);
		
		bounceMode = bounceMode_;
		
		// Enable the bounce mode
		if (bounceMode)
		{
            // Backup the regular settings
            aepChannelSettingsOrderedByActiveHardwareChannelsBackup.clear();            
            aepChannelSettingsOrderedByActiveHardwareChannels.swapWithArray(aepChannelSettingsOrderedByActiveHardwareChannelsBackup);

            // Get rid of the regular settings
			  aepChannelSettingsOrderedByActiveHardwareChannels.clear();  // Just to be sure..
			
			  // Use the ascending settings instead
            for (int i = 0; i != aepChannelSettingsOrderedByAepChannel.size(); ++i)
            {
                AepChannelSettings* theIthAepChannelSettings = aepChannelSettingsOrderedByAepChannel[i];
                aepChannelSettingsOrderedByActiveHardwareChannels.add(theIthAepChannelSettings);                
            }
		}
		
		// Disable the bounce mode
		else
		{
			// Recover the regular settings
            
			aepChannelSettingsOrderedByActiveHardwareChannels.swapWithArray(aepChannelSettingsOrderedByActiveHardwareChannelsBackup);
			aepChannelSettingsOrderedByActiveHardwareChannelsBackup.clear();
		}
		
		
		// Let the audioRegionMixer know about the new speaker configurations.
		positionOfSpeakers.clear();
		
		for (int i=0; i < aepChannelSettingsOrderedByActiveHardwareChannels.size(); i++)
		{
			SpeakerPosition theIthSpeaker(aepChannelSettingsOrderedByActiveHardwareChannels[i]->getSpeakerPosition());
			positionOfSpeakers.add(theIthSpeaker);
		}
		
		audioRegionMixer->setSpeakerPositions(positionOfSpeakers);
	}
	
	return aepChannelSettingsOrderedByActiveHardwareChannels.size();
}


void AudioSpeakerGainAndRouting::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
	DBG(T("AudioSpeakerGainAndRouting: prepareToPlay called."));
	
	if (audioSource != 0) {
		audioSource->prepareToPlay(samplesPerBlockExpected_, sampleRate_);
	}
	
	pinkNoiseGeneratorAudioSource.prepareToPlay(samplesPerBlockExpected_, sampleRate_);
	
}

// Implementation of the AudioSource method.
void AudioSpeakerGainAndRouting::releaseResources()
{
	DBG(T("AudioSpeakerGainAndRouting: releaseResources called."));
	
	if (audioSource != 0) {
		audioSource->releaseResources();
	}

}

// Implementation of the AudioSource method.
void AudioSpeakerGainAndRouting::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	
	// DBG(T("AudioSpeakerGainAndRouting: nr of channels = ") + String(info.buffer->getNumChannels()));
	// DBG(T("AudioSpeakerGainAndRouting::getNextAudioBlock called."));

	if (audioSource != 0)
	{
		// To save some typing and make the code more readable.
		int nrOfActiveHWChannels = aepChannelSettingsOrderedByActiveHardwareChannels.size();

		// Aquire a buffer of samples from the audioSource into the AudioSourceChannelInfo info.
		audioSource->getNextAudioBlock(info);
		
		// Before gain, mute or solo is applied to the audio stream, pink noise is
		// added if desired. Pink noise comes before the gain, so it is controllable 
		// on each channel via the corresponding gain.
		// pink noise
		// ----------
		if (numberOfChannelsWithActivatedPinkNoise != 0)
		{
			// At least one of the AEP channels (maybe not even a hardware output channel)
			// has pink noise engaged.
			
			// There is only one mono noise source for all channels.
			// Or stated differently: The noise on all channels is correlated
			// (which is good to judge the balance in loudness).
			
			// Generate the pink noise.
			

			if (pinkNoiseBuffer.getNumSamples() < info.buffer->getNumSamples())
			{
				pinkNoiseBuffer.setSize(1, info.buffer->getNumSamples());
			}
			
			pinkNoiseInfo.startSample = info.startSample;
			pinkNoiseInfo.numSamples = info.numSamples;
			pinkNoiseGeneratorAudioSource.getNextAudioBlock(pinkNoiseInfo);
			
			for (int n = 0; n < nrOfActiveHWChannels; n++)
			{
				// Add the pink noise to the channels that wants it.
				if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->getPinkNoiseStatus())
				{
					info.buffer->addFrom(n, info.startSample, 
										 pinkNoiseBuffer, 0, info.startSample, info.numSamples);
				}
			}
		}

		// gain	(only gain, nothing else)	
		if (numberOfMutedChannels == 0 && numberOfSoloedChannels == 0)
		{
			// neither a solo nor a mute
			for (int n = 0; n < nrOfActiveHWChannels; n++)
			{
				info.buffer->applyGainRamp(n, info.startSample, info.numSamples,
                    aepChannelSettingsOrderedByActiveHardwareChannels[n]->getLastGain(),
                    aepChannelSettingsOrderedByActiveHardwareChannels[n]->getGain());
				
				aepChannelSettingsOrderedByActiveHardwareChannels[n]->setLastGain(aepChannelSettingsOrderedByActiveHardwareChannels[n]->getGain());
			}
		}
		else
		{
			// mute or solo is engaged
			if (numberOfSoloedChannels > 0) 
			{
				// solo
				// ----
				// There is at least one solo in one channel enabled.
				// Soloing has a higher priority than muting. Meaning:
				// As soon as there is a channel soloed, muting doesn't
				// affect any channel anymore.
				for (int n = 0; n < nrOfActiveHWChannels; n++)
				{
					if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->getSoloStatus())
					{
						info.buffer->applyGain(n, info.startSample, info.numSamples, 
					        aepChannelSettingsOrderedByActiveHardwareChannels[n]->getGain());
					}
					else
					{
						info.buffer->clear(n, info.startSample, info.numSamples);						
					}
				}
				
			}
			else
			{
				// mute
				// ----
				for (int n = 0; n < nrOfActiveHWChannels; n++)
				{
					if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->getMuteStatus())
					{
						info.buffer->clear(n, info.startSample, info.numSamples);
					}
					else
					{
						info.buffer->applyGain(n, info.startSample, info.numSamples, 
							aepChannelSettingsOrderedByActiveHardwareChannels[n]->getGain());
					}
				}				
			}
		}
		
		// measurement (for drawing vu bars in the GUI)
		// -----------
		if (numberOfChannelsWithEnabledMeasurement != 0)
		{
			float sample = 0.0;
			const double decayFactor = 0.99992;
			for (int n = 0; n != nrOfActiveHWChannels; n++)
			{
				if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->getMeasurementStatus())
				{
					float decayingValue = aepChannelSettingsOrderedByActiveHardwareChannels[n]->getMeasuredDecayingValue();
					float peakValue = aepChannelSettingsOrderedByActiveHardwareChannels[n]->getMeasuredPeakValue();
					for (int i = 0; i < info.numSamples; ++i)
					{
						sample = std::abs( *info.buffer->getSampleData (n, info.startSample + i));
						if (sample > decayingValue)
						{
							decayingValue = sample;
						}
						else if (decayingValue > 0.001f)
						{
							decayingValue *= decayFactor;
						}
						else
						{
							decayingValue = 0.0;
						}
						
						if (sample > peakValue) {
							peakValue = sample;
						}
					}
					aepChannelSettingsOrderedByActiveHardwareChannels[n]->setMeasuredDecayingValue(decayingValue);
                    aepChannelSettingsOrderedByActiveHardwareChannels[n]->setMeasuredPeakValue(peakValue);
				}
			}
			
			
		}
	}
}

void AudioSpeakerGainAndRouting::updateThePositionOfSpeakers()
{
    positionOfSpeakers.clear();
    
    //for (int i = 0; i != numberOfActiveOutputChannels && i != aepChannelHardwareOutputPairs.size(); ++i)
    for (int i = 0; i != aepChannelSettingsOrderedByActiveHardwareChannels.size(); ++i)
        
    {
        // Fill the newPositionOfSpeakers array.
        SpeakerPosition theIthSpeaker(aepChannelSettingsOrderedByActiveHardwareChannels[i]->getSpeakerPosition());
        positionOfSpeakers.add(theIthSpeaker);
    }
	
    // Inform the audioRegionMixer about the new speaker configurations.
    audioRegionMixer->setSpeakerPositions(positionOfSpeakers);
}
