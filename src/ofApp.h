/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/ofxPd for documentation
 *
 */
#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxPd.h"
#include "ofxMidi.h"

// a namespace for the Pd types
using namespace pd;

// derive from Pd receiver classes to receieve message and midi events
class ofApp : public ofxiOSApp, public PdReceiver, public PdMidiReceiver, public ofxMidiListener, public ofxMidiConnectionListener {

	public:

		// main
		void setup();
		void update();
		void draw();
    void exit();

	
		void touchDown(ofTouchEventArgs &touch);
		void touchMoved(ofTouchEventArgs &touch);
		void touchUp(ofTouchEventArgs &touch);
		void touchDoubleTap(ofTouchEventArgs &touch);
		void touchCancelled(ofTouchEventArgs &touch);

		void lostFocus();
		void gotFocus();
		void gotMemoryWarning();
		void deviceOrientationChanged(int newOrientation);
		
		// audio callbacks
		void audioReceived(float * input, int bufferSize, int nChannels);
		void audioRequested(float * output, int bufferSize, int nChannels);
		
		// pd message receiver callbacks
		void print(const std::string& message);
		
		void receiveBang(const std::string& dest);
		void receiveFloat(const std::string& dest, float value);
		void receiveSymbol(const std::string& dest, const std::string& symbol);
		void receiveList(const std::string& dest, const List& list);
		void receiveMessage(const std::string& dest, const std::string& msg, const List& list);
		
		// pd midi receiver callbacks
		void receiveNoteOn(const int channel, const int pitch, const int velocity);
		void receiveControlChange(const int channel, const int controller, const int value);
		void receiveProgramChange(const int channel, const int value);
		void receivePitchBend(const int channel, const int value);
		void receiveAftertouch(const int channel, const int value);
		void receivePolyAftertouch(const int channel, const int pitch, const int value);
		
		void receiveMidiByte(const int port, const int byte);
	
		// do something
    bool drawSquares[2];
    string printMessage = " ";
	
		// sets the preferred sample rate, returns the *actual* samplerate
		// which may be different ie. iPhone 6S only wants 48k
		float setAVSessionSampleRate(float preferredSampleRate);
    
		ofxPd pd;
		vector<float> scopeArray;
		vector<Patch> instances;
		
        int midiChan;
    
    
    
    //MIDI
    // add a message to the display queue
    void addMessage(string msg);
    
    // midi message callback
    void newMidiMessage(ofxMidiMessage& msg);
    
    // midi device (dis)connection event callbacks
    void midiInputAdded(string name, bool isNetwork);
    void midiInputRemoved(string name, bool isNetwork);
    
    void midiOutputAdded(string nam, bool isNetwork);
    void midiOutputRemoved(string name, bool isNetwork);
    
    vector<ofxMidiIn*> inputs;
    vector<ofxMidiOut*> outputs;
    
    deque<string> messages;
    int maxMessages;
    ofMutex messageMutex; // make sure we don't read from queue while writing
    
    int note, ctl;
    vector<unsigned char> bytes;
};
