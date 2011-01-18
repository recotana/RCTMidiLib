//
//  RCTMidiLib.m,¥m
//  RCTMidiLib
//
//  Created by osamu funada on 11/01/17.
//  Copyright 2011 recotana.com All rights reserved.
//

#import "RCTMidiLib.h"



@interface RCTMidiLib(Private)


-(void)sendPacketList:(const MIDIPacketList*)aPacketList;

-(void)sendMidi:(const UInt8*)data size:(UInt32)size;


-(void)connectSource:(MIDIEndpointRef)aSource;
-(void)disconnectSource:(MIDIEndpointRef)aSource;

-(void)addDeviceProperty:(NSDictionary*)aDevice;
-(void)removeDeviceProperty:(NSDictionary*)aDevice;

-(MIDIEntityRef)entityWithEndpointRef:(MIDIEndpointRef)aSource;
-(MIDIDeviceRef)deviceWithEndpointRef:(MIDIEndpointRef)aSource;

-(NSDictionary*)dictionaryEndpointWithEndpointRef:(MIDIEndpointRef)aSource;
-(NSDictionary*)dictionaryEntityWithDeviceRef:(MIDIEntityRef)aEntity;
-(NSDictionary*)dictionaryDivceWithDeviceRef:(MIDIDeviceRef)aDevice;

-(void)addText:(NSString*)aText;
-(OSStatus)errorStatus:(OSStatus)aStatus message:(NSString*)aMessage;
-(NSError*)errorWithOSStatus:(OSStatus)aStatus message:(NSString*)aMessage;

@end


void midiNotificationProcess(const MIDINotification *message, void *ref);
void midiReadProcess(const MIDIPacketList *packetList, void *readProcRef, void *srcConnRef);

const MIDIPacketList *sharedPacketList;


@implementation RCTMidiLib
@synthesize delegate;
@synthesize devices;

-(id)init{
	if (self=[super init]) {
		
		OSStatus error;
		
		error=MIDIClientCreate((CFStringRef)@"RCTMidiLib Client", midiNotificationProcess, self, &client);
		if(error){
			[self errorStatus:error message:@"Init-MIDIClientCreate"];
			return nil;
		}
		
		error=MIDIOutputPortCreate(client, (CFStringRef)@"RCTMidiLib-OutPort", &outPort);
        if(error){
			[self errorStatus:error message:@"Init-MIDIOutputPortCreate"];
		    return nil;
		}
		
		error=MIDIInputPortCreate(client, (CFStringRef)@"RCTMidiLib-InPort", midiReadProcess, self, &inPort);
        if(error){
			[self errorStatus:error message:@"Init-MIDIInputPortCreate"];
			return nil;
		}
		
		devices=[[NSMutableArray alloc] init];
	}
	return self;
}
-(void)dealloc{
	[self disconnectAllSources];
	
	if(client)	MIDIClientDispose(client);
	if(outPort)	MIDIPortDispose(outPort);
	if(inPort)	MIDIPortDispose(inPort);
	[devices release];
	[super dealloc];
}



#pragma mark -- source connect/disconnect --

/*
 すべてのソースをInputPortへ接続
 */
-(void)connectAllSources{

	for (ItemCount index = 0; index < MIDIGetNumberOfSources() ; ++index)
		[self connectSource:MIDIGetSource(index)];

}

/*
 指定したエンドポイントのソースをInputPortへ接続
 */
-(void)connectSource:(MIDIEndpointRef)aSource{

	OSStatus error;
	
	error=MIDIPortConnectSource(inPort, aSource, self);
    if(error){ 
		[self errorStatus:error message:@"Connect-MIDIPortConnectSource"];
	    return;
	}
	
	NSDictionary *deviceDic=[self dictionaryDivceWithDeviceRef:[self deviceWithEndpointRef:aSource]];
	NSDictionary *endpointDic=[self dictionaryEndpointWithEndpointRef:aSource];
	if(deviceDic && endpointDic){
		
		[self addDeviceProperty:deviceDic];
		
		if([self.delegate respondsToSelector:@selector(connectMidiSource:device:)]){
			[self.delegate connectMidiSource:endpointDic device:deviceDic];
		}
		
	}
}

/*
 すべてのソースを切断
 */
-(void)disconnectAllSources{
	
	for (ItemCount index = 0 ; index < MIDIGetNumberOfSources() ; ++index)
		[self disconnectSource:MIDIGetSource(index)];
	
}

/*
 指定したエンドポイントのソースを切断
 */
-(void)disconnectSource:(MIDIEndpointRef)aSource{
	
	OSStatus error;
	
	error=MIDIPortDisconnectSource(inPort, aSource);
    if(error){
		[self errorStatus:error message:@"Disconnect-MIDIPortDisconnectSource"];
		return;
	}
	
	NSDictionary *deviceDic=[self dictionaryDivceWithDeviceRef:[self deviceWithEndpointRef:aSource]];
	NSDictionary *endpointDic=[self dictionaryEndpointWithEndpointRef:aSource];
	if(deviceDic && endpointDic){
		[self removeDeviceProperty:deviceDic];
		if([self.delegate respondsToSelector:@selector(disconnectMidiSource:device:)]){
			[self.delegate disconnectMidiSource:endpointDic device:deviceDic];
		}	
	}
	
}

-(void)addDeviceProperty:(NSDictionary*)aDevice{
	
	MIDIUniqueID uid=[[aDevice objectForKey:@"uniqueID"] intValue];
	
	for(NSDictionary *device in devices){
		if([[device objectForKey:@"uniqueID"] intValue]==uid) return;
	}
	[devices addObject:aDevice];
//	[self addText:[NSString stringWithFormat:@"+++++++++++ add device!!!! device count=%d\n\n",[devices count]]];
}

-(void)removeDeviceProperty:(NSDictionary*)aDevice{
	MIDIUniqueID uid=[[aDevice objectForKey:@"uniqueID"] intValue];
	
	for(NSInteger index=0; index<[devices count] ; index++){
		NSDictionary *device=[devices objectAtIndex:index];
		
		if([[device objectForKey:@"uniqueID"] intValue] == uid){
			[devices removeObjectAtIndex:index];
		//	[self addText:[NSString stringWithFormat:@"--------------  delete device!!!! device count=%d\n\n",[devices count]]];
		}
	}
	
	
}

#pragma mark -- midi send --

-(void)sendNoteOnFlag:(BOOL)aOnFlag noteNo:(Byte)aNo velocity:(Byte)aVelocity channel:(Byte)aChannel{
	
	Byte packet[3];
	if(aOnFlag==NO || ( aOnFlag==NO && aNo==0x90 && aVelocity==0 ) ){
		packet[0] = 0x80 + (aChannel&0x0F);
	}
	else{
		packet[0] = 0x90 + (aChannel&0x0F);
	}
	packet[1] = aNo;
	packet[2] = aVelocity;
	[self sendMidi:packet size:3 ];
}

-(void)sendCC7No:(Byte)aCCNo data:(Byte)aData channel:(Byte)aChannel{
	Byte packet[3];
	packet[0] = kMesControlChange + (aChannel&0x0F);
	packet[1] = (aCCNo&0x7F);
	packet[2] = (aData&0x7F);
	[self sendMidi:packet size:3 ];
}

-(void)sendCC14No:(Byte)aCCNo data:(UInt16)aData channel:(Byte)aChannel {
}

-(void)sendPolyKeyPressNoteNo:(Byte)aNoteNo press:(Byte)aPress channel:(Byte)aChannel{
	Byte packet[3];
	packet[0] = kMesPolyKeyPress + (aChannel&0x0F);
	packet[1] = (aNoteNo&0x7F);
	packet[2] = (aPress&0x7F);
	[self sendMidi:packet size:3 ];
}

-(void)sendChPress:(Byte)aPress channel:(Byte)aChannel{
	Byte packet[2];
	packet[0] = kMesChPress + (aChannel&0x0F);
	packet[1] = (aPress&0x7F);
	[self sendMidi:packet size:2];
}

-(void)sendPitchBendData:(UInt16)aData channel:(Byte)aChannel{
	
	UInt16 data=uint16_normalize(aData);
	
	Byte packet[3];
	packet[0] = kMesPitchBend + (aChannel&0x0F);
	packet[1] = lsb_comvert(data);
	packet[2] = msb_comvert(data);
	[self sendMidi:packet size:3];
//	[self addText:[NSString stringWithFormat:@"*** send pitchbend:%0X %0X %0X -- %0X\n",packet[0],packet[1],packet[2],data]];
}



/*
 すべてのDestinationへ送信
 */
- (void)sendMidi:(const UInt8*)data size:(UInt32)size
{
//	[self addText:[NSString stringWithFormat:@"%X %X %X",data[0],data[1],data[2]]];
	
	
	assert(size < 65536);
    Byte packetBuffer[size+100];
	
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer; //確保したバッファをMIDIPacketListへキャスト
    MIDIPacket     *packet     = MIDIPacketListInit(packetList); //packetListを初期化し、この先頭アドレスを返す
	MIDITimeStamp time=0;
	

		//packetListへMIDIデータを追加
		packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, time, size, data);
		

	
	[self sendPacketList:packetList];

}

-(void)sendPacketList:(MIDIPacketList*)aPacketList{
	
	OSStatus error;
	
	//すべてのDestinationへ送信
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index){
		
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
		
        if (outputEndpoint){
			error=MIDISend(outPort, outputEndpoint, aPacketList);
			
            if(!error) continue;
			else if([self.delegate respondsToSelector:@selector(sendErrorWithPacketList:)]){
				[self.delegate sendErrorWithPacketList:aPacketList];
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
	
	
    for (UInt32 i = 0; i < sharedPacketList->numPackets; ++i)
    {
		Byte messsage = packet->data[0] & 0xF0;
		Byte channel = packet->data[0] & 0x0F;
		
		if ((messsage == kMesNoteON) && (packet->data[2] != 0)) {
			if([self.delegate respondsToSelector:@selector(noteOnFlag:noteNo:velocity:channel:)]){
				[self.delegate noteOnFlag:YES noteNo:packet->data[1] velocity:packet->data[2] channel:channel];
			//	[self addText:[NSString stringWithFormat:@"R NoteON: %X %X %X -- ",packet->data[0],packet->data[1],packet->data[2]]];
			}	
		}
		else if (messsage == kMesNoteOFF || messsage == kMesNoteON) {
			if([self.delegate respondsToSelector:@selector(noteOnFlag:noteNo:velocity:channel:)]){
				[self.delegate noteOnFlag:NO noteNo:packet->data[1] velocity:packet->data[2] channel:channel];
			//	[self addText:[NSString stringWithFormat:@"R NoteOFF: %X %X %X -- ",packet->data[0],packet->data[1],packet->data[2]]];
			}
		}
		else if (messsage == kMesControlChange) {
			if([self.delegate respondsToSelector:@selector(controlChangeWithNumber:data:channnel:)]){
				[self.delegate controlChangeWithNumber:packet->data[1] data:packet->data[2] channnel:channel];
			//	[self addText:[NSString stringWithFormat:@"R CC: %X %X %X -- ",packet->data[0],packet->data[1],packet->data[2]]];
			}
		}
		else if (messsage == kMesPolyKeyPress) {
			if([self.delegate respondsToSelector:@selector(polyKeyPressNoteNo:press:channel:)]){
				[self.delegate polyKeyPressNoteNo:packet->data[1] press:packet->data[2] channel:channel];
				//	[self addText:[NSString stringWithFormat:@"R CC: %X %X %X -- ",packet->data[0],packet->data[1],packet->data[2]]];
			}
		}
		else if (messsage == kMesChPress) {
			if([self.delegate respondsToSelector:@selector(channelPress:channel:)]){
				[self.delegate channelPress:packet->data[1] channel:channel];
				//	[self addText:[NSString stringWithFormat:@"R CC: %X %X %X -- ",packet->data[0],packet->data[1],packet->data[2]]];
			}
		}
		else if (messsage == kMesPitchBend) {

			UInt32 value=uint16_combine(packet->data[2],packet->data[1]);
			if([self.delegate respondsToSelector:@selector(pitchBendData:channel:)]){
				[self.delegate pitchBendData:value channel:channel];
			//	[self addText:[NSString stringWithFormat:@"R CC: %X %X %X -- ",packet->data[0],packet->data[1],packet->data[2]]];
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
	RCTMidiLib *self=(RCTMidiLib*)readProcRef;
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
	RCTMidiLib *self=(RCTMidiLib*)ref;
	
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
		
		case kMIDIMsgIOError:
			if([self.delegate respondsToSelector:@selector(midiMessageError:)]){
				[self.delegate midiMessageError:(const MIDIIOErrorNotification*)notification];
			}
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
			
			
		default:
            break;
    }
}

#pragma mark -- get property --



-(MIDIEntityRef)entityWithEndpointRef:(MIDIEndpointRef)aSource{
	
	OSStatus error;
	MIDIEntityRef entity;
	
	error=MIDIEndpointGetEntity( aSource , &entity );
	if(error){
		[self errorStatus:error message:@"MIDIEndpointGetEntity"];
		return nil;
	}
	return entity;
}

-(MIDIDeviceRef)deviceWithEndpointRef:(MIDIEndpointRef)aSource{
	
	MIDIEntityRef entity=[self entityWithEndpointRef:aSource];
	
	OSStatus error;
	MIDIDeviceRef device;
	
	error=MIDIEntityGetDevice( entity , &device );
	if(error){
		[self errorStatus:error message:@"MIDIEntityGetDevice"];
		return nil;
	}
	return device;
}

-(NSDictionary*)dictionaryEndpointWithEndpointRef:(MIDIEndpointRef)aSource{
	
	OSStatus error;
	NSDictionary *dic;
	CFPropertyListRef property = nil;
	
	error=MIDIObjectGetProperties(aSource, &property, true);
	
	if(error){
		[self errorStatus:error message:@"MIDIObjectGetProperties-Endpoint"];
		return nil;
	}
	dic=[NSDictionary dictionaryWithDictionary:(NSDictionary*)property];
	CFRelease(property);
	
	return dic;
}

-(NSDictionary*)dictionaryEntityWithDeviceRef:(MIDIEntityRef)aEntity{
	
	OSStatus error;
	NSDictionary *dic;
	CFPropertyListRef property = nil;
	
	error=MIDIObjectGetProperties( aEntity, &property, true);
	if(error){
		[self errorStatus:error message:@"MIDIObjectGetProperties-Entity"];
		return nil;
	}
	
	dic=[NSDictionary dictionaryWithDictionary:(NSDictionary*)property];
	CFRelease(property);
	
	return dic;
}

-(NSDictionary*)dictionaryDivceWithDeviceRef:(MIDIDeviceRef)aDevice{
	
	OSStatus error;
	NSDictionary *dic;
	CFPropertyListRef property = nil;
	
	error=MIDIObjectGetProperties( aDevice, &property, true);
	if(error){
		[self errorStatus:error message:@"MIDIObjectGetProperties-Device"];
		return nil;
	}
	
	dic=[NSDictionary dictionaryWithDictionary:(NSDictionary*)property];
	CFRelease(property);
	
	return dic;
}


#pragma mark -- Logging --

-(void)addText:(NSString*)aText{
	if([self.delegate respondsToSelector:@selector(addLogMidiText:)]){
		[self.delegate  performSelectorOnMainThread:@selector(addLogMidiText:)
										 withObject:aText
									  waitUntilDone:NO];
	}
}

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
