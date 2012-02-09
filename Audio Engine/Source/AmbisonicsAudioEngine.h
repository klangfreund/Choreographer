/*
 *  AmbisonicsAudioEngine.h
 *  AudioPlayer
 *
 *  Created by sam on 10 04 01.
 *  Copyright 2010 klangfreund.com. All rights reserved.
 *
 */

#ifndef __AMBISONICS_AUDIO_ENGINE
#define __AMBISONICS_AUDIO_ENGINE

#include "../JuceLibraryCode/JuceHeader.h"
#include "modified Juce Classes/AudioTransportSourceMod.h"
#include "AudioSpeakerGainAndRouting.h"
#include "AudioRegionMixer.h"


// ------------------------------------------------------------
/**
 An ambisonics audio engine for the Choreographer.
 
 (It is used by AudioEngine.mm).
 
 \image html 101017_code_overview.png
 */
class AmbisonicsAudioEngine
{
public:
	/**
	 The constructor of AmbisonicsAudioEngine.
	 
	 Creates an AmbisonicsAudioEngine object.
	 */
	AmbisonicsAudioEngine ();
	
	/**
	 The destructor.
	 */
	~AmbisonicsAudioEngine ();	
	
	/**
	 Opens a dialogWindow to set up the audioDeviceManager.
	 
	 THIS WILL BE REMOVED SOON.
	 */
	void showAudioSettingsWindow();

	/**
	 Returns the names of all available Core Audio devices.
	 
	 @return	The names of all available Core Audio devices.
				If there is none, an empty array is returned.
	 */
     StringArray getAvailableAudioDeviceNames ();

	/**
	 Sets the Core Audio device to be used for the audio output.
	 
	 @return	An error message if anything went wrong.
                An empty string otherwise.
	 */
	String setAudioDevice (const String& audioDeviceName);
	
	/**
	 Returns the name of the currently used Audio IO Device.
	 
	 @return	The name of the currently used Audio IO Device.
	 */
	const String & getNameOfCurrentAudioDevice ();
    
    /**
     Returns a list of the names of all output channels of the
     currently used audio io device.
     
     @return    A list of the names of all output channels of the
                currently used audio io device.
     */
    StringArray getOutputChannelNames();
    
    /**
     Returns the available samplerates of the currently used
     audio io device.
     
     @return    The available samplerates of the currently used
                audio io device.
     */
     Array<double> getAvailableSampleRates();
    
	/**
	 Sets the sample rate the current audio io device should
     operate in.
     To know which sample rates are supported, call
     getAvailableSampleRates().
	 
	 @return	An error message if anything went wrong.
     An empty string otherwise.
	 */
     String setSampleRate(const double& sampleRate);

	/**
	 Returns the currently used sample rate of the audio io device.
	 
	 @return The currently used sample rate of the audio io device.
	 */
	double getCurrentSampleRate ();
    
    /**
     Returns the available buffer sizes of the currently used audio device
     in samples.
     */
    Array<int> getAvailableBufferSizes();
    
    /**
     Returns the default buffer size of the currently used audio device
     in samples.
     */
    int getDefaultBufferSize();
    
    /**
     Returns the currently used buffer size of the currently used audio device.
     
     Measured in samples.
     */
    int getCurrentBufferSize();
    
    String setBufferSize(const int & bufferSizeInSamples);

    
//    int getCurrentBitDepth();
//    
//    bool showControlPanel();
//    
//    int getOutputLatencyInSamples();
	
	/**
	 Returns the number of output channels of the current
	 AudioIODevice.
	 
	 @return The number of output channels.
	 */
	int getNumberOfHardwareOutputChannels();

	/** Get the number of aep channels with a speaker configuration assigned
	 to them (by setSpeakerPosition).
	 */	
	int getNumberOfAepChannels();
	
	/** Write the specified interval to a file.
	 
	 Please only call this after the arranger has been stopped.
	 
	 @param absolutePathToAudioFile	The absolute path to the audio file.
	 @param bitsPerSample			The desired bit depth.
	 @param description				For the wav-metadata: description.
	 @param originator				For the wav-metadata: originator.
	 @param originatorRef			For the wav-metadata: originatorRef.
	 @param timeReferenceSamples	For the wav-metadata: timeReferenceSamples.
	 @param codingHistory			For the wav-metadata: codingHistory.
	 @param startSample				From where the bouncing should begin
	 @param numberOfSamplesToRead	The number of samples to bounce.
	 
	 @return						True, if the operation was successful.
	 */	
	bool bounceToDisk(String absolutePathToAudioFile, 
					  int bitsPerSample, 
					  String description,
					  String originator,
					  String originatorRef,
					  String codingHistory,
					  int startSample,
					  int numberOfSamplesToRead);
    
    void cancelBounceToDisk();
	
	/** Adds a new AEP channel to the array of AEP channels.
	 
	 If the specified channel is already there, this operation aborts.	 
	 If n := aepChannel and m := array.size < n-1, then additional channels
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
	
    /** Set the speaker position in space for an AEP channel.
	 
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
	 
	 Multiple aepChannels can have the solo engaged.
	 Solo has a higher priority than mute. E.g. if you solo a muted
	 aepChannel, the audio will get through.
	 */
	bool setSolo(int aepChanel, bool enable);
	
	/** Enables or disables the mute mode of the chosen aepChannel.

	 */
	bool setMute(int aepChanel, bool enable);
	
	/** Enables or disables the output of pink noise on the chosen aepChannel.
	 */
	bool activatePinkNoise(int aepChanel, bool enable);
	
	/** Sets the amplitude of the pink noise generator.
	 * This affects the volume of all pink noises on all channels.
	 * Setting a new amplitude won't result in a click, since a gain
	 * ramp is applied to avoid it.
	 */
	void setAmplitudeOfPinkNoiseGenerator(const double amplitude);
	
	/** Enables or disables the measurement for the chosen aepChannel.
	 */
	bool enableMeasurement(int aepChannel, bool enable);
	
	/** Resets the measured peak value to zero.
	 */
	bool resetMeasuredPeakValue(int aepChannel);
	
	/** Returns the measured decaying value.
	 
	 This method is intended to be used by some visualization element
	 e.g. by a VU meter.
	 */
	float getMeasuredDecayingValue(int aepChannel);
	
	/** Returns the measured peak value.
	 
	 This method is intended to be used by some visualization element
	 e.g. by a VU meter.
	 */
	float getMeasuredPeakValue(int aepChannel);	
	
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
	 
	 To enable this state, call enableNewRouting.
	 */	
	void removeAllRoutings();
	
	/** It activates the hardware channels needed for the desired
	 routing and assignes the corresponding AEP settings to them.
	 
	 It will stop the playback, if it was running.
	 
	 The resulting assignments of speaker configurations (for the 
	 active hardware channels) are transmitted to the AudioRegionMixer.
	*/
	void enableNewRouting();
	
	/** Removes all connections between the AEP channels and
	 the audio hardware output channels as well as all AEP
	 channels.
	 
	 Use this with care! The playback will be stopped when calling this.
	 */
	void removeAllRoutingsAndAllAepChannels();

	/**
	 Returns the current position, measured in samples.
	 
	 @return    The current position, measured in samples.
	 */
	int getCurrentPosition ();
	
	/**
	 Set the position of the play head.
	 
	 @param positionInSamples	Specifies the location where the play head should be
	 placed at (in samples).
	 */
	void setPosition(int positionInSamples);
	
	/**
	 Starts the playback.
	 */
	void start();
	
	/**
	 Stops the playback.
	 */
	void stop();
	
	/**
	 Turns the loop (as specified in the arranger) on.
	 
	 @param loopFadeTimeInSeconds	Is used as the fade out and fade in time -
                                    around the jump from the end to the start 
                                    marker of the loop (to avoid clicks).
	 
	 @return	True, if the input data is a valid set.
	 */
	bool enableArrangerLoop(double loopStartInSeconds, 
                            double loopEndInSeconds, 
                            double loopFadeTimeInSeconds = 0.005);
	
	/**
	 Turns the loop off.
	 */
	void disableArrangerLoop();
	
	/**
	 Returns the average proportion of available CPU being spent inside the audio callbacks.
	 But since most of the processing is done in the buffering thread, this information is
	 not very useful.
	 
	 It might be better to remove this function (or even better: replace it with a useful
	 function).
	 
	 @return A value between 0.0 and 1.0, representing the CPU usage of the audio callbacks.
	 */
	double getCpuUsage ();
	
	/**
	 Creates and adds an audio region.
	 
	 The regions are managed by the AudioRegionMixer, by the way.
	 
	 @param regionID                 This ID must be unique for every region, such
	                                 that the region can be modified or be deleted 
					 later.
	 
	 @param startPosition            Specifies the start position of the region (in
	                                 samples).
	 
	 @param duration                 Specifies the duration of the region (in samples).
	 
	 @param offsetInFile             This offset (greater or equal 0, measured in 
					 samples) defines the position in the audio file 
					 that has to be at the beginning of the (visual 
	                                 block called) audio region.
	 
	 @param absolutePathToAudioFile  The absolute path to the audio file.
	 */
	bool addAudioRegion (const int regionID,
					     const int startPosition,
					     const int duration,
					     const int offsetInFile,
					     String absolutePathToAudioFile);
	
	/**
	 Modifies an audio region (that was originally created by addAudioRegion).
	 
	 The regions are managed by the AudioRegionMixer, by the way.
	 
	 @param regionID                 This unique ID specifies the region that should be
	                                 modified.
	 
	 @param newStartPosition         Specifies the new start position of the region (in
                                         samples).
	 
	 @param newDuration              Specifies the duration of the region (in samples).
	 
	 @param newOffsetInFile          This new offset (>=0, in samples) defines the 
	                                 position in the audio file that has to be at the 
					 beginning of the (visual block called) audio 
					 region.
	
	 @return			 The success of this operation.
	 */
	bool modifyAudioRegion (const int regionID,
						    const int newStartPosition,
						    const int newDuration,
						    const int newOffsetInFile);

	/**
	 Removes an audio region (that was originally created by addAudioRegion).
	 
	 The regions are managed by the AudioRegionMixer, by the way.
	 
	 @param regionID                 This unique ID specifies the region that should 
	                                 be modified.

	 @return			 The success of this operation.
	 */
	bool removeRegion (const int regionID);

	/**
	 Removes all audio regions (originally created by addAudioRegion).

	 The regions are managed by the AudioRegionMixer, by the way.
	 */
	void removeAllRegions ();
	
	/**
	 Attaches a gain envelope to a region.

	 The gain envelope contains points - pairs of time (in samples) and volume values.
	 These define the change of volume over time. Linear interpolation is used.
	 For all time instances before the first point, the volume value of the first point is
	 used. For all time instances after the last point, the volume value of the last point
	 is used.

	 @param regionID		The ID of the region.
	 @param gainEnvelope            A gainEnvelope is a void*-Array. The void 
	                                pointers need to be typecasted to pointers to
	                                AudioEnvelopePoint
					( (AudioEnvelopePoint*)gainEnvelope[pointNumber_StartingAtZero] ).
					The gainEnvelope and all involved AudioEnvelopePoints
					will be deleted in
					AudioSourceGainEnvelope::setGainEnvelope 
					or in AudioSourceGainEnvelope::~AudioSourceGainEnvelope,
					so you don't have to care about.

	 @return		 	The success of this operation.
	 */
	bool setGainEnvelopeForRegion (const int regionID, Array<void*> gainEnvelope);
	
	/** 
	 Sets the output gain ( the "master gain").

	 @param newGain			The samples of the output stream will be
	 				multiplied by this value.
	 */	
	void setMasterGain(const float newGain);
	
	/**
	 Sets the order used in AudioSourceAmbipanning.
	 
	 */
	void setAEPOrder (const double order);
	
	/**
	 Sets the distanceMode used in AudioSourceAmbipanning to 0.	 
	 */
	void setAEPDistanceModeTo0 ();
	
	/**
	 Sets the distanceMode used in AudioSourceAmbipanning to 1.
	 In this mode, some values are needed, which have to be
	 specified here.
     
     Exponential decrease.
	 */
	void setAEPDistanceModeTo1 (double centerRadius, 
								double centerExponent,
								double centerAttenuationInDB,
								double dBFalloffPerUnit);

	/**
	 Sets the distanceMode used in AudioSourceAmbipanning to 2.
	 In this mode, some values are needed, which have to be
	 specified here.
     
     Inverse proportional decrease.
	 */
	void setAEPDistanceModeTo2 (double centerRadius, 
								double centerExponent,
								double centerAttenuationInDB,
								double outsideCenterExponent);
	
	/**
	 Attaches a spacial envelope to a region. 

	 The spacial envelope contains points. Such a point holds four values: The position
	 (the time information, measured in samples, starting at the beginning of the audiofile
	 - not at the beginning of a region with an offset) and the x, y and z coordinates.
	 The spacial envelope defines the change of the coordinates over time. Linear interpolation
	 of the resulting gain values for the speakers for this source is used in between points.
	 For all time instances before the first point, the coordinates of the first point is
	 used. For all time instances after the last point, the coordinates of the last point
	 is used.

	 @param regionID		The ID of the region.
	 @param spacialEnvelope         A spacialEnvelope is a void*-Array. The void 
	                                pointers need to be typecasted to pointers to
	                                SpacialEnvelopePoint
					( (SpacialEnvelopePoint*)spacialEnvelope[pointNumber_StartingAtZero] ).
					The spacialEnvelope and all involved
					SpacialEnvelopePoints will be deleted in the 
					AudioSourceAmbipanning::setSpacialEnvelope
					or in the 
					AudioSourceAmbipanning::~AudioSourceAmbipanning,
					so you don't have to care about.

	 @return		 	The success of this operation.
	 */
	bool setSpacialEnvelopeForRegion (const int& regionID, const Array<SpacialEnvelopePoint>& spacialEnvelope);
	
	
private:
	AudioDeviceManager audioDeviceManager;		///< An instance of a Juce object. 
							///  This is the connection to 
							///  the audio hardware. See the Juce 
							///  documentation.

	AudioSourcePlayer audioSourcePlayer;		///< An instance of a Juce object.
							///  The adapter between the
							///  AudioDeviceManager and an AudioSource.
							///  See the Juce documentation.
		
	AudioTransportSourceMod audioTransportSource;	///< An instance of a modified Juce object.

	AudioSpeakerGainAndRouting audioSpeakerGainAndRouting;
	
	AudioRegionMixer audioRegionMixer;		///< An instance of a new object, manages 
							///  and mixes audio regions.
	
	//TODO: Maybe this is not used anymore
	Array<void*> positionOfSpeakerMaybeReduced;	///< An instance of a Juce array of void*.
							///  The void pointers
							///  need to be typecasted to pointers to
							///  SpeakerPosition
							///  ( (SpeakerPosition*)positionOfSpeaker[SpeakerNumber-1] ).
							///  A reduction of elements - in comparison
							///  with AmbisonicsAudioEngine::positionOfSpeaker - migh 
							///  happen if 
							///  there are less available hardware outputs
							///  then speakers. This is done in 
							///  AmbisonicsAudioEngine::setSpeakerPositions.
    
    /** This can be set by cancelBounceToDisk to interrupt the
     bouncing process and delete the output file.
     */
    bool stopBounceToDisk;
	
	/** Used for scope locking in enableNewRouting. */
    CriticalSection lock;
	
	JUCE_LEAK_DETECTOR (AmbisonicsAudioEngine);
};

#endif // __AMBISONICS_AUDIO_ENGINE
