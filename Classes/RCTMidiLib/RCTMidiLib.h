//
//  RCTMidiLib.h
//  RCTMidiLib
//
//  Created by osamu funada on 11/01/17.
//  Copyright 2011 recotana.com All rights reserved.
//


#import <CoreMIDI/CoreMIDI.h>

#define uint16_normalize(uint16_data) (uint16_data>0x3FFF) ? 0x3FFF : uint16_data;
#define uint16_combine(byte_msb,byte_lsb) (UInt16)(byte_msb<<7)+byte_lsb
#define msb_comvert(uint16_data) (Byte)((uint16_data & 0x3FFF) >> 7)
#define lsb_comvert(uint16_data) (Byte)(uint16_data & 0x007F) 

enum{
	kMesNoteOFF			= 0x80,
	kMesNoteON			= 0x90,
	kMesPolyKeyPress	= 0xA0,
	kMesControlChange	= 0xB0,
	kMesProgramChange	= 0xC0,
	kMesChPress			= 0xD0,
	kMesPitchBend		= 0xE0
	
};


@protocol RCTMidiLibDelegate 
@optional

/*
 midi recieve delegate method
 */
-(void)noteOnFlag:(BOOL)aOnFlag noteNo:(Byte)aNumber velocity:(Byte)aVelocity channel:(Byte)aChannel;
-(void)controlChangeWithNumber:(Byte)aNumber data:(Byte)aData channnel:(Byte)aChannel;
-(void)polyKeyPressNoteNo:(Byte)aNoteNo press:(Byte)aPress channel:(Byte)aChannel;
-(void)channelPress:(Byte)aPress channel:(Byte)aChannel;
-(void)pitchBendData:(UInt16)aData channel:(Byte)aChannel;

/*
 midi send delegate method
 */
-(void)sendErrorWithPacketList:(MIDIPacketList*)aPacketList;


/*
 midi notifications delegate method
 */

-(void)connectMidiSource:(NSDictionary*)aSourceProperty device:(NSDictionary*)aDeviceProperty;
-(void)disconnectMidiSource:(NSDictionary*)aSourceProperty device:(NSDictionary*)aDeviceProperty;

-(void)midiObjectAdded:(const MIDIObjectAddRemoveNotification *)notification;
-(void)midiObjectRemoved:(const MIDIObjectAddRemoveNotification *)notification;
-(void)midiMessageError:(const MIDIIOErrorNotification*)notification;


/*
 midi error delegate method
 */
-(void)midiError:(NSError*)aError;

@end


@interface RCTMidiLib : NSObject{
	
 @private
	MIDIClientRef	client;
    MIDIPortRef		inPort;
    MIDIPortRef		outPort;
	
	id delegate;
	NSMutableArray *devices;
}
@property(assign) id delegate;
@property(nonatomic,retain) NSArray *devices;




/*
 midi send note on/off
 
 OnFlag	: YES -- Note ON
 OnFlag	: NO  -- Note OFF
 
 noteNo	: 0-127
 velocity: 0-127
 channel : 0-16
 */
-(void)sendNoteOnFlag:(BOOL)aOnFlag noteNo:(Byte)aNo velocity:(Byte)aVelocity channel:(Byte)aChannel;

/*
 midi send control change (7bit data Only)
 
 No  : 0-127 (0-63などは省くべきか）
 data: 0-127
 channel : 0-16
 */
-(void)sendCC7No:(Byte)aCCNo data:(Byte)aData channel:(Byte)aChannel;

//-(void)sendCC14No:(Byte)aCCNo data:(UInt32)aData channel:(Byte)aChannel;


/*
 midi send Polyphonic Key Pressure 
 
 No  : 0-127 
 press: 0-127
 channel : 0-16
 */
-(void)sendPolyKeyPressNoteNo:(Byte)aNoteNo press:(Byte)aPress channel:(Byte)aChannel;

/*
 midi send Channel Pressure 

 press: 0-127
 channel : 0-16
 */
-(void)sendChPress:(Byte)aPress channel:(Byte)aChannel;

/*
 midi send Pitch Bend 
 
 data: 0-127
 channel : 0-16
 */
-(void)sendPitchBendData:(UInt16)aData channel:(Byte)aChannel;





/*
 MIDI Device Control
 */
-(void)connectAllSources;
-(void)disconnectAllSources;




@end

