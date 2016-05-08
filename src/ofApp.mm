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
#include "ofApp.h"

#import <AVFoundation/AVFoundation.h>

#pragma mark standard of func
//--------------------------------------------------------------
void ofApp::setup() {

	ofSetFrameRate(60);
	ofSetVerticalSync(true);
	//ofSetLogLevel("Pd", OF_LOG_VERBOSE); // see verbose info inside

	// register touch events
	ofRegisterTouchEvents(this);
	
	// initialize the accelerometer
//	ofxAccelerometer.setup();
	
	// iOSAlerts will be sent to this
	ofxiOSAlerts.addListener(this);
	
	// set landscape
	//ofSetOrientation(OF_ORIENTATION_90_RIGHT;
	
	// try to set the preferred iOS sample rate, but get the actual sample rate
	// being used by the AVSession since newer devices like the iPhone 6S only
	// want specific values (ie 48000 instead of 44100)
	float sampleRate = setAVSessionSampleRate(48000);
	
	// the number if libpd ticks per buffer,
	// used to compute the audio buffer len: tpb * blocksize (always 64)
	int ticksPerBuffer = 8; // 8 * 64 = buffer len of 512

	// setup OF sound stream using the current *actual* samplerate
	ofSoundStreamSetup(2, 1, this, sampleRate, ofxPd::blockSize()*ticksPerBuffer, 3);

	// setup Pd
	//
	// set 4th arg to true for queued message passing using an internal ringbuffer,
	// this is useful if you need to control where and when the message callbacks
	// happen (ie. within a GUI thread)
	//
	// note: you won't see any message prints until update() is called since
	// the queued messages are processed there, this is normal
	//
	if(!pd.init(2, 1, sampleRate, ticksPerBuffer, false)) {
		OF_EXIT_APP(1);
	}

	midiChan = 1; // midi channels are 1-16

	// subscribe to receive source names
	pd.subscribe("toOF");

	// add message receiver, required if you want to receieve messages
	pd.addReceiver(*this);   // automatically receives from all subscribed sources

	// add midi receiver, required if you want to recieve midi messages
	pd.addMidiReceiver(*this);  // automatically receives from all channels

	// add the data/pd folder to the search path
	pd.addToSearchPath("pd/abs");
	// audio processing on
	pd.start();

    ///MIDI
    /////////
    maxMessages = 28;
    messages.push_back("nothing yet ...");
    
    note = -1;
    ctl  = -1;
    
    // enables the network midi session between iOS and Mac OSX on a
    // local wifi network
    //
    // in ofxMidi: open the input/outport network ports named "Session 1"
    //
    // on OSX: use the Audio MIDI Setup Utility to connect to the iOS device
    //
    ofxMidi::enableNetworking();
    
    // list the number of available input & output ports
    ofxMidiIn::listPorts();
    ofxMidiOut::listPorts();
    
    // create and open input ports
    for(int i = 0; i < ofxMidiIn::getNumPorts(); ++i) {
        
        // new object
        inputs.push_back(new ofxMidiIn);
        
        // set this class to receive incoming midi events
        inputs[i]->addListener(this);
        
        // open input port via port number
        inputs[i]->openPort(i);
    }
    
    // create and open output ports
    for(int i = 0; i < ofxMidiOut::getNumPorts(); ++i) {
        
        // new object
        outputs.push_back(new ofxMidiOut);
        
        // open input port via port number
        outputs[i]->openPort(i);
    }
    
    // set this class to receieve midi device (dis)connection events
    ofxMidi::setConnectionListener(this);

}

//--------------------------------------------------------------
void ofApp::update() {
	// since this is a test and we don't know if init() was called with
	// queued = true or not, we check it here
	if(pd.isQueued()) {
		// process any received messages, if you're using the queue and *do not*
		// call these, you won't receieve any messages or midi!
		pd.receiveMessages();
		pd.receiveMidi();
	}

	// update scope array from pd
	//pd.readArray("scope", scopeArray);
}

//--------------------------------------------------------------
void ofApp::draw() {

    //ofBackground(255);
    
//    if(drawSquares[0]){
//        ofSetColor(ofColor::red);
//        ofDrawRectangle(0, 0, ofGetWidth()/2, ofGetHeight());
//        drawSquares[0] = false;
//    }
//    if(drawSquares[1]){
//        ofSetColor(ofColor::blue);
//        ofDrawRectangle(ofGetWidth()/2, 0, ofGetWidth()/2, ofGetHeight());
//        drawSquares[1] = false;
//    }
//	// draw scope
//	ofSetColor(0, 255, 0);
//	ofSetRectMode(OF_RECTMODE_CENTER);
//	float x = 0, y = ofGetHeight()/2;
//	float w = ofGetWidth() / (float) scopeArray.size(), h = ofGetHeight()/2;
//	for(int i = 0; i < scopeArray.size()-1; ++i) {
//		ofDrawLine(x, y+scopeArray[i]*h, x+w, y+scopeArray[i+1]*h);
//		x += w;
//	}
    ofSetColor(ofColor::red);
    ofDrawBitmapString(printMessage, 20,20);
//    ofDrawBitmapString("ola", 20, 20);
//    ofTrueTypeFont font;
//    font.load(OF_TTF_MONO, 40);
    
    
    //MIDI
    ofSetColor(0);
    
    ofDrawBitmapString("Input:", 10, 20);
    int x = 10, y = 34;
    messageMutex.lock();
    deque<string>::iterator iter = messages.begin();
    for(; iter != messages.end(); ++iter) {
        ofDrawBitmapString((*iter), x, y);
        y += 14;
    }
    messageMutex.unlock();
    
    ofDrawBitmapString("Output:", 10, ofGetHeight()-42);
    if(note > 0) {
        ofDrawBitmapString("note "+ofToString(note), 10, ofGetHeight()-28);
        ofDrawRectangle(80, ofGetHeight()-38, ofMap(note, 0, 127, 0, ofGetWidth()-10), 12);
    }
    if(ctl > 0) {
        ofDrawBitmapString("pan "+ofToString(ctl), 10, ofGetHeight()-14);
        ofDrawRectangle(80, ofGetHeight()-24, ofMap(ctl, 0, 127, 0, ofGetWidth()-10), 12);
    }
}
void ofApp::exit(){
    // clean up
    
    for(int i = 0; i < inputs.size(); ++i) {
        inputs[i]->closePort();
        inputs[i]->removeListener(this);
        delete inputs[i];
    }
    
    for(int i = 0; i < outputs.size(); ++i) {
        outputs[i]->closePort();
        delete outputs[i];
    }
}

#pragma mark DeviceEvents
//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch) {
	// y pos changes pitch
//	int pitch = (-1 * (touch.y/ofGetHeight()) + 1) * 127;
//	playTone(pitch);
    pd.sendBang("fromOF");
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs &touch) {}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs &touch) {}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs &touch) {}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs& args) {}

//--------------------------------------------------------------
void ofApp::lostFocus() {}

//--------------------------------------------------------------
void ofApp::gotFocus() {}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning() {}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation) {}


# pragma mark AudioUpdateEvents
//--------------------------------------------------------------
void ofApp::audioReceived(float * input, int bufferSize, int nChannels) {
	pd.audioIn(input, bufferSize, nChannels);
}

//--------------------------------------------------------------
void ofApp::audioRequested(float * output, int bufferSize, int nChannels) {
	pd.audioOut(output, bufferSize, nChannels);
}

#pragma mark PDreceiveEvents
//--------------------------------------------------------------
void ofApp::print(const std::string& message) {
	cout << message << endl;
}

//--------------------------------------------------------------
void ofApp::receiveBang(const std::string& dest) {
	cout << "OF: bang " << dest << endl;
}

void ofApp::receiveFloat(const std::string& dest, float value) {
	cout << "OF: float " << dest << ": " << value << endl;
    ofSetColor(ofColor::red);
    switch ((int)value) {
        case 24:
            addMessage("clock!!!!");
            drawSquares[0] = true;
            ofSetColor(0);
            printMessage += "24";
            break;
        case 12:
            drawSquares[1] = true;
            ofSetColor(ofColor::blue);
            ofDrawRectangle(ofGetWidth()/2, 0, ofGetWidth()/2, ofGetHeight());
            break;
        case 13:
            addMessage("received start clock message");
            break;
        case 14:
            addMessage("received noteOn into pd");
            break;
        default:
            break;
    }
}

void ofApp::receiveSymbol(const std::string& dest, const std::string& symbol) {
	cout << "OF: symbol " << dest << ": " << symbol << endl;
}

void ofApp::receiveList(const std::string& dest, const List& list) {
	cout << "OF: list " << dest << ": ";

	// step through the list
	for(int i = 0; i < list.len(); ++i) {
		if(list.isFloat(i))
			cout << list.getFloat(i) << " ";
		else if(list.isSymbol(i))
			cout << list.getSymbol(i) << " ";
	}

	// you can also use the built in toString function or simply stream it out
	// cout << list.toString();
	// cout << list;

	// print an OSC-style type string
	cout << list.types() << endl;
}

void ofApp::receiveMessage(const std::string& dest, const std::string& msg, const List& list) {
	cout << "OF: message " << dest << ": " << msg << " " << list.toString() << list.types() << endl;
}

//--------------------------------------------------------------
void ofApp::receiveNoteOn(const int channel, const int pitch, const int velocity) {
	cout << "OF MIDI: note on: " << channel << " " << pitch << " " << velocity << endl;
    ofSetColor(0);
    printMessage += "pitch";
}

void ofApp::receiveControlChange(const int channel, const int controller, const int value) {
	cout << "OF MIDI: control change: " << channel << " " << controller << " " << value << endl;
}

// note: pgm nums are 1-128 to match pd
void ofApp::receiveProgramChange(const int channel, const int value) {
	cout << "OF MIDI: program change: " << channel << " " << value << endl;
}

void ofApp::receivePitchBend(const int channel, const int value) {
	cout << "OF MIDI: pitch bend: " << channel << " " << value << endl;
}

void ofApp::receiveAftertouch(const int channel, const int value) {
	cout << "OF MIDI: aftertouch: " << channel << " " << value << endl;
}

void ofApp::receivePolyAftertouch(const int channel, const int pitch, const int value) {
	cout << "OF MIDI: poly aftertouch: " << channel << " " << pitch << " " << value << endl;
}

// note: pd adds +2 to the port num, so sending to port 3 in pd to [midiout],
//       shows up at port 1 in ofxPd
void ofApp::receiveMidiByte(const int port, const int byte) {
	cout << "OF MIDI: midi byte: " << port << " " << byte << endl;
}

#pragma mark system midi events
//--------------------------------------------------------------
void ofApp::addMessage(string msg) {
    messageMutex.lock();
    cout << msg << endl;
    messages.push_back(msg);
    while(messages.size() > maxMessages)
        messages.pop_front();
    messageMutex.unlock();
}

//--------------------------------------------------------------
void ofApp::newMidiMessage(ofxMidiMessage& msg) {
    addMessage(msg.toString());
    switch (msg.status) {
        case MIDI_NOTE_ON:
            pd.sendNoteOn(midiChan, msg.pitch, msg.velocity);
            break;
        case MIDI_START:
            pd.sendSysRealTime(midiChan, msg.value);
        default:
            break;
    }
}

//--------------------------------------------------------------
void ofApp::midiInputAdded(string name, bool isNetwork) {
    stringstream msg;
    msg << "ofxMidi: input added: " << name << " network: " << isNetwork;
    addMessage(msg.str());
    
    // create and open a new input port
    ofxMidiIn * newInput = new ofxMidiIn;
    newInput->openPort(name);
    newInput->addListener(this);
    inputs.push_back(newInput);
}

//--------------------------------------------------------------
void ofApp::midiInputRemoved(string name, bool isNetwork) {
    stringstream msg;
    msg << "ofxMidi: input removed: " << name << " network: " << isNetwork << endl;
    addMessage(msg.str());
    
    // close and remove input port
    vector<ofxMidiIn*>::iterator iter;
    for(iter = inputs.begin(); iter != inputs.end(); ++iter) {
        ofxMidiIn * input = (*iter);
        if(input->getName() == name) {
            input->closePort();
            input->removeListener(this);
            delete input;
            inputs.erase(iter);
            break;
        }
    }
}

//--------------------------------------------------------------
void ofApp::midiOutputAdded(string name, bool isNetwork) {
    stringstream msg;
    msg << "ofxMidi: output added: " << name << " network: " << isNetwork << endl;
    addMessage(msg.str());
    
    // create and open new output port
    ofxMidiOut * newOutput = new ofxMidiOut;
    newOutput->openPort(name);
    outputs.push_back(newOutput);
}

//--------------------------------------------------------------
void ofApp::midiOutputRemoved(string name, bool isNetwork) {
    stringstream msg;
    msg << "ofxMidi: output removed: " << name << " network: " << isNetwork << endl;
    addMessage(msg.str());
    
    // close and remove output port
    vector<ofxMidiOut*>::iterator iter;
    for(iter = outputs.begin(); iter != outputs.end(); ++iter) {
        ofxMidiOut * output = (*iter);
        if(output->getName() == name) {
            output->closePort();
            delete output;
            outputs.erase(iter);
            break;
        }
    }
}

#pragma mark audio aux func
//--------------------------------------------------------------
// set the samplerate the Apple approved way since newer devices
// like the iPhone 6S only allow certain sample rates,
// the following code may not be needed once this functionality is
// incorporated into the ofxiOSSoundStream
// thanks to Seth aka cerupcat
float ofApp::setAVSessionSampleRate(float preferredSampleRate) {
	
	NSError *audioSessionError = nil;
	AVAudioSession *session = [AVAudioSession sharedInstance];

	// disable active
	[session setActive:NO error:&audioSessionError];
	if (audioSessionError) {
		NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
	}

	// set category
	[session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionDefaultToSpeaker error:&audioSessionError];
	if(audioSessionError) {
		NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
	}

	// try to set the preferred sample rate
	[session setPreferredSampleRate:preferredSampleRate error:&audioSessionError];
	if(audioSessionError) {
		NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
	}

	// *** Activate the audio session before asking for the "current" values ***
	[session setActive:YES error:&audioSessionError];
	if (audioSessionError) {
		NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
	}
	ofLogNotice() << "AVSession samplerate: " << session.sampleRate << ",  I/O buffer duration: " << session.IOBufferDuration;

	// our actual samplerate, might be differnt aka 48k on iPhone 6S
	return session.sampleRate;
}
