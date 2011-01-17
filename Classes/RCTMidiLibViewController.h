//
//  MidiTestForiPadViewController.h
//  MidiTestForiPad
//
//  Created by recotana on 11/01/17.
//  Copyright 2011 recotana.com All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTMidiLib.h"

@interface RCTMidiLibViewController : UIViewController<RCTMidiLibDelegate> {

	RCTMidiLib *midi;
	
	NSMutableString *text;
	
	IBOutlet UILabel *deviceNameLabel;
	IBOutlet UITextView *recieveView;
	
	IBOutlet UIButton *sendButton1;
	IBOutlet UIButton *sendButton2;
	
	IBOutlet UISlider *sliderCC;
	IBOutlet UISlider *sliderPKP;
	IBOutlet UISlider *sliderCP;
	IBOutlet UISlider *sliderPB;
	
	IBOutlet UILabel *labelCC;
	IBOutlet UILabel *labelPKP;
	IBOutlet UILabel *labelCP;
	IBOutlet UILabel *labelPB;
	
	IBOutlet UIButton *clearButton;
}
@property(nonatomic,retain) NSMutableString *text;

@property(nonatomic,retain) IBOutlet UILabel *deviceNameLabel;
@property(nonatomic,retain) IBOutlet UITextView *recieveView;

@property(nonatomic,retain) IBOutlet UIButton *sendButton1;
@property(nonatomic,retain) IBOutlet UIButton *sendButton2;

@property(nonatomic,retain) IBOutlet UISlider *sliderCC;
@property(nonatomic,retain) IBOutlet UISlider *sliderPKP;
@property(nonatomic,retain) IBOutlet UISlider *sliderCP;
@property(nonatomic,retain) IBOutlet UISlider *sliderPB;

@property(nonatomic,retain) IBOutlet UILabel *labelCC;
@property(nonatomic,retain) IBOutlet UILabel *labelPKP;
@property(nonatomic,retain) IBOutlet UILabel *labelCP;
@property(nonatomic,retain) IBOutlet UILabel *labelPB;

@property(nonatomic,retain) IBOutlet UIButton *clearButton;



-(void)initialize;



-(void)addLogMidiText:(NSString*)aText;
-(IBAction)clearAction:(UIButton*)sender;


-(IBAction)sendNoteAction:(UIButton*)sender;

-(IBAction)sendSliderAction:(UISlider*)sender;
-(IBAction)pitchBendOffAction:(UISlider*)sender;


@end

