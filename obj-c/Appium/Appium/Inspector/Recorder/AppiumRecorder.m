//
//  AppiumRecorderDelegate.m
//  Appium
//
//  Created by Dan Cuellar on 4/13/13.
//  Copyright (c) 2013 Appium. All rights reserved.
//

#import "AppiumRecorder.h"

#import <Selenium/SERemoteWebDriver.h>
#import <QuartzCore/QuartzCore.h>
#import "AppiumInspector.h"
#import "AppiumCodeMakerActions.h"

@interface AppiumRecorder ()
    @property (readonly) AppiumInspector *inspector;
    @property (readonly) SERemoteWebDriver *driver;
@end

@implementation AppiumRecorder

-(id) init
{
    self = [super init];
    if (self) {
		_isRecording = NO;
        [self setKeysToSend:@""];
    }
    return self;
}

#pragma mark - Private Properties
-(AppiumInspector*)inspector { return _windowController.inspector; }
-(SERemoteWebDriver*)driver { return _windowController.driver; }

#pragma mark - Public Properties
-(NSNumber*) isRecording { return [NSNumber numberWithBool:_isRecording]; }
-(void) setIsRecording:(NSNumber *)isRecording
{
	_isRecording = [isRecording boolValue];
}

#pragma mark - Actions
-(IBAction)tap:(id)sender
{
    AppiumCodeMakerLocator *locator = [self.inspector locatorForSelectedNode];
    
    AppiumCodeMakerAction *action = [[AppiumCodeMakerActionTap alloc] initWithLocator:locator];
	if (_isRecording)
	{
		[_codeMaker addAction:action];
	}
    action.block(self.driver);
    [self.inspector refresh:sender];
}

-(IBAction)sendKeys:(id)sender
{

    AppiumCodeMakerLocator *locator = [self.inspector locatorForSelectedNode];
    
    NSString *keysToSend = [self.keysToSend copy];
    
    AppiumCodeMakerAction *action = [[AppiumCodeMakerActionSendKeys alloc] initWithLocator:locator keys:keysToSend];
	if (_isRecording)
	{
		[_codeMaker addAction:action];
	}
    action.block(self.driver);
    [self.inspector refresh:sender];
}

-(IBAction)comment:(id)sender
{
    NSString *comment = [self.keysToSend copy];
	if (_isRecording)
	{
		[_codeMaker addAction:[[AppiumCodeMakerActionComment alloc] initWithComment:comment]];
	}
}

-(IBAction)acceptAlert:(id)sender
{
    AppiumCodeMakerAction *action = [[AppiumCodeMakerActionAlertAccept alloc] init];
	if (_isRecording)
	{
		[_codeMaker addAction:action];
	}
	action.block(self.driver);
    [self.inspector refresh:sender];
}

-(IBAction)dismissAlert:(id)sender
{

    AppiumCodeMakerAction *action = [[AppiumCodeMakerActionAlertDismiss alloc] init];
	if (_isRecording)
	{
		[_codeMaker addAction:action];
	}
	action.block(self.driver);
    [self.inspector refresh:sender];
}

- (IBAction)toggleSwipePopover:(id)sender
{
	if (!_windowController.swipePopover.isShown) {
		[_windowController.selectedElementHighlightView setHidden:YES];
		[_windowController.swipePopover showRelativeToRect:[_windowController.swipeButton bounds]
                                                    ofView:_windowController.swipeButton
                                             preferredEdge:NSMaxYEdge];
	} else {
		[_windowController.swipePopover close];
		[_windowController.selectedElementHighlightView setHidden:NO];
	}
}

-(IBAction)performSwipe:(id)sender
{
	// perform the swipe
	NSArray *args = [[NSArray alloc] initWithObjects:[[NSDictionary alloc] initWithObjectsAndKeys:
													  [NSNumber numberWithInteger:_windowController.swipePopoverViewController.numberOfFingers], @"touchCount",
													  [NSNumber numberWithInteger:_windowController.swipePopoverViewController.beginPoint.x], @"startX",
													  [NSNumber numberWithInteger:_windowController.swipePopoverViewController.beginPoint.y], @"startY",
													  [NSNumber numberWithInteger:_windowController.swipePopoverViewController.endPoint.x], @"endX",
													  [NSNumber numberWithInteger:_windowController.swipePopoverViewController.endPoint.y], @"endY",
													  [_windowController.swipePopoverViewController.duration copy], @"duration",
													  nil],nil];

    AppiumCodeMakerAction *action = [[AppiumCodeMakerActionSwipe alloc] initWithArguments:args];
	if (_isRecording)
	{
		[_codeMaker addAction:action];
	}
    action.block(self.driver);
	
	// reset for next iteration
	[_windowController.swipePopover close];
	[_windowController.swipePopoverViewController reset];
	[_windowController.selectedElementHighlightView setHidden:NO];
	[self.inspector refresh:sender];
}

-(IBAction)toggleRecording:(id)sender
{
	[self setIsRecording:[NSNumber numberWithBool:!_isRecording]];
	if (_isRecording)
	{
		[_windowController.bottomDrawer openOnEdge:NSMinYEdge];
        
        CIFilter *filter = [CIFilter filterWithName:@"CIFalseColor"];
        [filter setDefaults];
        [filter setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forKey:@"inputColor0"];
        [filter setValue:[CIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] forKey:@"inputColor1"];
        [filter setName:@"pulseFilter"];
        [_windowController.recordButton.layer setFilters:[NSArray arrayWithObject:filter]];
        
        CABasicAnimation* pulseAnimation1 = [CABasicAnimation animation];
        pulseAnimation1.keyPath = @"filters.pulseFilter.inputColor1";
        pulseAnimation1.fromValue = [CIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:0.9];
        pulseAnimation1.toValue = [CIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
        pulseAnimation1.duration = 1.5;
        pulseAnimation1.repeatCount = HUGE_VALF;
        pulseAnimation1.autoreverses = YES;
        
        [_windowController.recordButton.layer addAnimation:pulseAnimation1 forKey:@"pulseAnimation1"];
		NSShadow * shadow = [NSShadow new];
		[shadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.95f]];
		[_windowController.recordButton setShadow:shadow];
	}
	else
	{
		[_windowController.recordButton setShadow:nil];
        [_windowController.recordButton.layer setFilters:[NSArray new]];
        [_windowController.recordButton.layer removeAllAnimations];
		[_windowController.bottomDrawer close];
	}
}

-(IBAction)clearRecording:(id)sender
{
	[_codeMaker reset];
}

-(IBAction)replay:(id)sender
{
    [_codeMaker replay:self.driver];
}

@end
