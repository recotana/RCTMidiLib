//
//  MidiLib.m
//  MIDITest
//
//  Created by osamu funada on 11/01/04.
//  Copyright 2011 recotana. All rights reserved.
//

#import "MidiLib.h"

void midiNotificationProcess(const MIDINotification *message, void *ref);
void midiReadProcess(const MIDIPacketList *packetList, void *readProcRef, void *srcConnRef);

const MIDIPacketList *sharedPacketList;


@implementation MidiLib
@synthesize delegate;

-(id)init{
	if (self=[super init]) {
		
		OSStatus error;
		
		error=MIDIClientCreate((CFStringRef)@"MidiLib Client", midiNotificationProcess, self, &client);
		if(error){
			[self errorStatus:error message:@"Init-MIDIClientCreate"];
			return nil;
		}
		
		error=MIDIOutputPortCreate(client, (CFStringRef)@"MidiLib-OutPort", &outPort);
        if(error){
			[self errorStatus:error message:@"Init-MIDIOutputPortCreate"];
		    return nil;
		}
		
		error=MIDIInputPortCreate(client, (CFStringRef)@"MidiLib-InPort", midiReadProcess, self, &inPort);
        if(error){
			[self errorStatus:error message:@"Init-MIDIInputPortCreate"];
			return nil;
		}

	}
	return self;
}
-(void)dealloc{
	if(client)	MIDIClientDispose(client);
	if(outPort)	MIDIPortDispose(outPort);
	if(inPort)	MIDIPortDispose(inPort);
	[super dealloc];
}



#pragma mark -- source connect/disconnect --

/*
 すべてのソースをInputPortへ接続する
 */
-(void)connectAllSources{

	for (ItemCount index = 0; index < MIDIGetNumberOfSources() ; ++index)
		[self connectSource:MIDIGetSource(index)];

}

/*
 指定したエンドポイントのソースをInputPortへ接続する
 */
-(void)connectSource:(MIDIEndpointRef)aSource{

	OSStatus error;
	
	error=MIDIPortConnectSource(inPort, aSource, self);
    if(error){ 
		[self errorStatus:error message:@"Connect-MIDIPortConnectSource"];
	    return;
	}
	
	NSDictionary *entityDic=[self dictionaryEntityWithEndpointRef:aSource];
	NSDictionary *endpointDic=[self dictionaryEndpointWithEndpointRef:aSource];
	if(entityDic && endpointDic){
		if([self.delegate respondsToSelector:@selector(connectMidiSource:entity:)]){
			[self.delegate connectMidiSource:endpointDic entity:entityDic];
		}
	}
}

/*
 すべてのソースを切断する
 */
-(void)disconnectAllSources{
	
	for (ItemCount index = 0; index < MIDIGetNumberOfSources() ; ++index)
		[self disconnectSource:MIDIGetSource(index)];
	
}

/*
 指定したエンドポイントのソースを切断する
 */
-(void)disconnectSource:(MIDIEndpointRef)aSource{
	
	OSStatus error;
	
	error=MIDIPortDisconnectSource(inPort, aSource);
    if(error){
		[self errorStatus:error message:@"Disconnect-MIDIPortDisconnectSource"];
		return;
	}
	
	NSDictionary *entityDic=[self dictionaryEntityWithEndpointRef:aSource];
	NSDictionary *endpointDic=[self dictionaryEndpointWithEndpointRef:aSource];
	if(entityDic && endpointDic){
		if([self.delegate respondsToSelector:@selector(disconnectMidiSource:entity:)]){
			[self.delegate disconnectMidiSource:endpointDic entity:entityDic];
		}
	}
	
}

#pragma mark -- midi send --
/*
 すべてのDestinationへ送信
 */
- (void)sendMidi:(const UInt8*)data size:(UInt32)size
{
	OSStatus error;
	
	assert(size < 65536);
    Byte packetBuffer[size+100];
	
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
	
	//packetListへMIDIデータを追加
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, data);
	
	//すべてのDestinationへ送信
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index){
		
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
		
        if (outputEndpoint){
			error=MIDISend(outPort, outputEndpoint, packetList);
			
            if(!error) continue;
			else if([self.delegate respondsToSelector:@selector(sendErrorWithPacketList:)]){
					[self.delegate sendErrorWithPacketList:packetList];
			}
		}
		
    }
	
}


#pragma mark -- midi recieve --

/*
 MIDI受信処理(メインスレッド）
 */
-(void)recieveProcess{
	
	//MIDIPacketList先頭データを取得
    MIDIPacket *packet = (MIDIPacket *)&(sharedPacketList->packet[0]);
	
	Byte messsage = packet->data[0] & 0xF0;
	Byte channel = packet->data[0] & 0x0F;
	
	
    for (UInt32 i = 0; i < sharedPacketList->numPackets; ++i)
    {
		if ((messsage == 0x90) && (packet->data[2] != 0)) {
			if([self.delegate respondsToSelector:@selector(noteOnWithNumber:velocity:channel:)]){
				[self.delegate noteOnWithNumber:packet->data[1] velocity:packet->data[2] channel:channel];
			}	
		}
		else if (messsage == 0x80 || messsage == 0x90) {
			if([self.delegate respondsToSelector:@selector(noteOffWithNumber:velocity:channel:)]){
				[self.delegate noteOffWithNumber:packet->data[1] velocity:packet->data[2] channel:channel];
			}
		}
		else if (messsage == 0xB0) {
			if([self.delegate respondsToSelector:@selector(controlChangeWithNumber:data:channnel:)]){
				[self.delegate controlChangeWithNumber:packet->data[1] data:packet->data[2] channnel:channel];
			}
		}
		packet = MIDIPacketNext(packet);
    }

}

/*
  MIDI受信コールバック(バックグラウンドスレッド）
 */
void midiReadProcess(const MIDIPacketList *packetList, void *readProcRef, void *srcConnRef)
{
	MidiLib *self=(MidiLib*)readProcRef;
	sharedPacketList=packetList;
	
	//メインスレッド側のMIDI受信処理メソッドを呼ぶ
	[self performSelectorOnMainThread:@selector(recieveProcess)
						   withObject:nil
						waitUntilDone:NO];
	
}


#pragma mark -- Notification --
- (void)addEndpoint:(const MIDIObjectAddRemoveNotification *)notification
{
	if (notification->childType == kMIDIObjectType_Source){
        [self connectSource:(MIDIEndpointRef)notification->child];
		
	}
    else if (notification->childType == kMIDIObjectType_Destination){}
}

- (void)removeEndpoint:(const MIDIObjectAddRemoveNotification *)notification
{
	if (notification->childType == kMIDIObjectType_Source){
        [self disconnectSource:(MIDIEndpointRef)notification->child];
	}
    else if (notification->childType == kMIDIObjectType_Destination){
	}
}

void midiNotificationProcess(const MIDINotification *notification, void *ref)
{
	MidiLib *self=(MidiLib*)ref;
	
	switch (notification->messageID)
    {
        case kMIDIMsgObjectAdded:
            [self addEndpoint:(const MIDIObjectAddRemoveNotification *)notification];
            break;
			
        case kMIDIMsgObjectRemoved:
            [self removeEndpoint:(const MIDIObjectAddRemoveNotification *)notification];
            break;
        
        case kMIDIMsgPropertyChanged:
			break;
		/*
        case kMIDIMsgThruConnectionsChanged:
			if([self.delegate respondsToSelector:@selector(midiThruConnectChanged:)]){
				[self.delegate midiThruConnectChanged:(const MIDIObjectPropertyChangeNotification*)notification];
			}
			break;
        case kMIDIMsgSerialPortOwnerChanged:
			if([self.delegate respondsToSelector:@selector(midiSerialportOrnerChanged:)]){
				[self.delegate midiSerialportOrnerChanged:(const MIDIObjectPropertyChangeNotification*)notification];
			}
			break;
		 */
        case kMIDIMsgIOError:
			if([self.delegate respondsToSelector:@selector(midiMessageError:)]){
				[self.delegate midiMessageError:(const MIDIIOErrorNotification*)notification];
			}
			break;
			
		default:
            break;
    }
}

#pragma mark -- get property --

-(NSDictionary*)dictionaryEndpointWithEndpointRef:(MIDIEndpointRef)aSource{
	
	OSStatus error;
	NSDictionary *propertyDic;
	CFPropertyListRef property = nil;
	
	error=MIDIObjectGetProperties(aSource, &property, true);
	
	if(error){
		[self errorStatus:error message:@"MIDIObjectGetProperties"];
		return nil;
	}
	propertyDic=[NSDictionary dictionaryWithDictionary:(NSDictionary*)property];
	CFRelease(property);
	
	return propertyDic;
}

-(NSDictionary*)dictionaryEntityWithEndpointRef:(MIDIEndpointRef)aSource{
	
	OSStatus error;
	NSDictionary *entityDic;
	CFPropertyListRef property = nil;
	
	MIDIEntityRef entity;
	
	error=MIDIEndpointGetEntity( aSource , &entity );
	if(error){
		[self errorStatus:error message:@"MIDIEndpointGetEntity"];
		return nil;
	}
	
	error=MIDIObjectGetProperties( entity, &property, true);
	if(error){
		[self errorStatus:error message:@"MIDIObjectGetProperties"];
		return nil;
	}

	entityDic=[NSDictionary dictionaryWithDictionary:(NSDictionary*)property];

	CFRelease(property);
	
	return entityDic;
}




#pragma mark -- Logging --



-(OSStatus)errorStatus:(OSStatus)aStatus message:(NSString*)aMessage{
	
	if(aStatus){
		if([self.delegate respondsToSelector:@selector(midiError:)]){
			[self.delegate  performSelectorOnMainThread:@selector(midiError:)
											 withObject:[self errorWithOSStatus:aStatus message:aMessage]
											  waitUntilDone:NO];
		}
	}
	
	return aStatus;
}

-(NSError*)errorWithOSStatus:(OSStatus)aStatus message:(NSString*)aMessage{
	
	NSDictionary *dic=[NSDictionary dictionaryWithObject:aMessage 
												  forKey:NSLocalizedFailureReasonErrorKey];
	
	return [NSError errorWithDomain:NSOSStatusErrorDomain 
							   code:aStatus 
						   userInfo:dic];
}
@end
