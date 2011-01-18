//
//  MidiTestForiPadViewController.m
//  MidiTestForiPad
//
//  Created by recotana on 11/01/17.
//  Copyright 2011 recotana.com All rights reserved.
//

#import "RCTMidiLibViewController.h"

@implementation RCTMidiLibViewController
@synthesize text;
@synthesize deviceNameLabel;
@synthesize recieveView;
@synthesize sendButton1,sendButton2,clearButton;
@synthesize sliderCC,sliderPKP,sliderCP,sliderPB;
@synthesize labelCC,labelPKP,labelCP,labelPB;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization 
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self initialize];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[text release];
	[midi release];
    [super dealloc];
}

#pragma mark -- initialize --

-(void)initialize{
	
	//MIDIライブラリ初期化
	midi=[[RCTMidiLib alloc] init];
	midi.delegate=self;
	
	//Dockコネクタへ接続されているMIDI機器のソースをすべて接続する
	[midi connectAllSources];
	
	
	
	//-- view init ---
	self.text=[NSMutableString string];
	
	labelCC.text=[NSString stringWithFormat:@"CC No:64  -- %d",(Byte)sliderCC.value];
	labelPKP.text=[NSString stringWithFormat:@"Poly Key Press No:13 -- %d",(Byte)sliderPKP.value];
	labelCP.text=[NSString stringWithFormat:@"Ch Press --  %d",(Byte)sliderCP.value];
	labelPB.text=[NSString stringWithFormat:@"PitchBend  --  %d",(UInt16)sliderPB.value];

}


#pragma mark -- view process --
/*
 recieveViewへの表示
 */
-(void)addLogMidiText:(NSString*)aText{
	[text insertString:aText atIndex:0];
	recieveView.text=text;
}


#pragma mark -- button action --
/*
 button action
 */
-(IBAction)sendNoteAction:(UIButton*)sender{
	Byte noteNo,velocity,channel=0;
	BOOL noteOnFlag;
	

	switch (sender.allControlEvents) {
		case UIControlEventTouchDown:
			noteOnFlag=YES;
			break;
		case UIControlEventTouchUpInside:
			noteOnFlag=NO;
			break;
		default:
			break;
	}
	
	if(sender==sendButton1){
		noteNo=0;
		velocity=127;
		channel=0;
	}
	else if(sender==sendButton2){
		noteNo=12;
		velocity=100;
		channel=2;
	}
	
	//send MIDI Note message
	[midi sendNoteOnFlag:noteOnFlag noteNo:noteNo velocity:velocity channel:channel];
	
}


-(IBAction)clearAction:(UIButton*)sender{
	self.text=[NSMutableString string];
	recieveView.text=nil;
}


#pragma mark -- slider action --
/*
 slider action
 */
-(IBAction)sendSliderAction:(UISlider*)sender{
	Byte channel=0;


	if(sender==sliderCC){
		[midi sendCC7No:64 data:(Byte)sender.value channel:channel];
	}
	else if(sender==sliderPKP){
		[midi sendPolyKeyPressNoteNo:13 press:(Byte)sender.value channel:channel]; 
	}
	else if(sender==sliderCP){
		[midi sendChPress:(Byte)sender.value channel:channel];
	}
	else if(sender==sliderPB){
		[midi sendPitchBendData:(UInt16)sender.value channel:channel];
	}
	
}

-(IBAction)pitchBendOffAction:(UISlider*)sender{
	Byte channel=0;
	[sender setValue:(float)0x3FFF/2 animated:YES];
	[midi sendPitchBendData:(UInt16)sender.value channel:channel];
}


#pragma mark -- delegate method : midi recieve process --
/*
 midi recieve  delegate method
 */
-(void)noteOnFlag:(BOOL)aOnFlag noteNo:(Byte)aNumber velocity:(Byte)aVelocity channel:(Byte)aChannel{
	NSString *flagStr=(aOnFlag!=YES) ? @"OFF" : @"ON";
	[self addLogMidiText:[NSString stringWithFormat:@"Rcieve Note %@ No:%d  velocity:%d  ch:%d\n",flagStr,aNumber,aVelocity,aChannel]];
}

-(void)controlChangeWithNumber:(Byte)aNumber data:(Byte)aData channnel:(Byte)aChannel{
	[self addLogMidiText:[NSString stringWithFormat:@"Rcieve CC No:%d  data:%d  ch:%d\n",aNumber,aData,aChannel]];
	labelCC.text=[NSString stringWithFormat:@"CC No:%d  -- %d",aNumber,aData];
}
-(void)polyKeyPressNoteNo:(Byte)aNoteNo press:(Byte)aPress channel:(Byte)aChannel{
	[self addLogMidiText:[NSString stringWithFormat:@"Rcieve PolyKeyPress No:%d  data:%d  ch:%d\n",aNoteNo,aPress,aChannel]];
	labelPKP.text=[NSString stringWithFormat:@"Poly Key Press No:%d -- %d",aNoteNo,aPress];
}
-(void)channelPress:(Byte)aPress channel:(Byte)aChannel{
	[self addLogMidiText:[NSString stringWithFormat:@"Rcieve ChannelPress press:%d  ch:%d\n",aPress,aChannel]];
	labelCP.text=[NSString stringWithFormat:@"Ch Press --  %d",aPress];
}
-(void)pitchBendData:(UInt16)aData channel:(Byte)aChannel{
	[self addLogMidiText:[NSString stringWithFormat:@"Rcieve PitchBend:0x%04X  ch:%d\n",aData,aChannel]];
	labelPB.text=[NSString stringWithFormat:@"PitchBend  --  0x%04X",aData];
}



#pragma mark -- delegate method : midi notification --
/*
 midi notification  delegate  method
 */

//MIDI Device Connect
-(void)connectMidiSource:(NSDictionary*)aSourceProperty device:(NSDictionary*)aDeviceProperty{
	deviceNameLabel.text=[NSString stringWithFormat:@"Device: %@",[aDeviceProperty objectForKey:@"name"]];
	[self addLogMidiText:[NSString stringWithFormat:@"connect!\n%@\n%@\n\n",[aDeviceProperty description],[aSourceProperty description]]];
}

//MIDI Device Disconnect
-(void)disconnectMidiSource:(NSDictionary*)aSourceProperty device:(NSDictionary*)aDeviceProperty{
	[self addLogMidiText:[NSString stringWithFormat:@"Disconnect..\n%@\n%@\n\n",[aDeviceProperty description],[aSourceProperty description]]];
	if([midi.devices count]==0) deviceNameLabel.text=@"Device: no connect";
}

/*
 midi error method
 */
-(void)midiError:(NSError*)aError{
	[self addLogMidiText:[NSString stringWithFormat:@"%@\n\n",[aError localizedDescription]]];
}



@end
