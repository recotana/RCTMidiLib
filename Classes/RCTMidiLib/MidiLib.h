//
//  MidiLib.h
//  MIDITest
//
//  Created by osamu funada on 11/01/04.
//  Copyright 2011 recotana. All rights reserved.
//


#import <CoreMIDI/CoreMIDI.h>

@protocol MidiLibDelegate 
@optional

/*
 midi recieve
 */
-(void)noteOnWithNumber:(Byte)aNumber velocity:(Byte)aVelocity channel:(Byte)aChannel;
-(void)noteOffWithNumber:(Byte)aNumber velocity:(Byte)aVelocity channel:(Byte)aChannel;
-(void)controlChangeWithNumber:(Byte)aNumber data:(Byte)aData channnel:(Byte)aChannel;

/*
 midi send
 */
-(void)sendErrorWithPacketList:(MIDIPacketList*)aPacketList;


/*
 midi notifications
 */

-(void)connectMidiSource:(NSDictionary*)aSourceProperty entity:(NSDictionary*)aEntityProperty;
-(void)disconnectMidiSource:(NSDictionary*)aSourceProperty entity:(NSDictionary*)aEntityProperty;

-(void)midiObjectAdded:(const MIDIObjectAddRemoveNotification *)notification;
-(void)midiObjectRemoved:(const MIDIObjectAddRemoveNotification *)notification;
-(void)midiMessageError:(const MIDIIOErrorNotification*)notification;


/*
 midi error
 */
-(void)midiError:(NSError*)aError;

@end


@interface MidiLib :NSObject{
	
 @private
	MIDIClientRef	client;
    MIDIPortRef		inPort;
    MIDIPortRef		outPort;
	
	id delegate;
	
}
@property(assign) id delegate;

-(void)sendMidi:(const UInt8*)data size:(UInt32)size;

-(void)connectAllSources;
-(void)connectSource:(MIDIEndpointRef)aSource;
-(void)disconnectAllSources;
-(void)disconnectSource:(MIDIEndpointRef)aSource;

-(NSDictionary*)dictionaryEndpointWithEndpointRef:(MIDIEndpointRef)aSource;
-(NSDictionary*)dictionaryEntityWithEndpointRef:(MIDIEndpointRef)aSource;


-(OSStatus)errorStatus:(OSStatus)aStatus message:(NSString*)aMessage;
-(NSError*)errorWithOSStatus:(OSStatus)aStatus message:(NSString*)aMessage;

@end
