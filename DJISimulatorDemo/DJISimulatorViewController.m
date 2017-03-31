//
//  DJISimulatorViewController.m
//
//  Copyright © 2015 DJI. All rights reserved.
//
/**
 *  This file demonstrates how to use the advanced set of methods in DJIFlightController to control the aircraft and how to start the simulator.
 *
 *  Through DJIFlightController, user can make the aircraft enter the virtual stick mode. In this mode, SDK gives the flexibility for user to control the aircraft just like controlling it using the virtual stick. There are different combinations to control the aircraft in the
 *  virtual stick mode. In this sample, we will control the horizontal movement by velocity. For more information about the virtual stick, please refer to the Flight Controller guide page on https://developer.dji.com/mobile-sdk/documentation/introduction/component-guide-flightController.html.
 *
 *  Through the simulator object in DJIFlightController, user can test the flight controller interfaces and Mission Manager without PC. In this sample, we will start/stop the simulator and display the aircraft's state during the simulation.
 *
 */

#import "DJISimulatorViewController.h"
#import "VirtualStickView.h"
#import "DemoUtility.h"
#import <DJISDK/DJISDK.h>

#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;

@interface DJISimulatorViewController ()<DJISimulatorDelegate>

@property(nonatomic, weak) IBOutlet VirtualStickView *virtualStickLeft;
@property(nonatomic, weak) IBOutlet VirtualStickView *virtualStickRight;

@property (weak, nonatomic) IBOutlet UIButton *simulatorButton;
@property (weak, nonatomic) IBOutlet UILabel *simulatorStateLabel;
@property (assign, nonatomic) BOOL isSimulatorOn;
@property (assign, nonatomic) float mXVelocity;
@property (assign, nonatomic) float mYVelocity;
@property (assign, nonatomic) float mYaw;
@property (assign, nonatomic) float mThrottle;

- (IBAction) onEnterVirtualStickControlButtonClicked:(id)sender;
- (IBAction) onExitVirtualStickControlButtonClicked:(id)sender;
- (IBAction) onTakeoffButtonClicked:(id)sender;
- (IBAction) onSimulatorButtonClicked:(id)sender;
- (IBAction) onLandButtonClicked:(id)sender;

@end

@implementation DJISimulatorViewController

#pragma mark - Inherited Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"DJISimulator Demo";
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: self
                           selector: @selector (onStickChanged:)
                               name: @"StickChanged"
                             object: nil];

}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    if (fc && fc.simulator) {
        self.isSimulatorOn = fc.simulator.isSimulatorActive;
        [self updateSimulatorUI];
        
        [fc.simulator addObserver:self forKeyPath:@"isSimulatorActive" options:NSKeyValueObservingOptionNew context:nil];
        [fc.simulator setDelegate:self];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    if (fc && fc.simulator) {
        [fc.simulator removeObserver:self forKeyPath:@"isSimulatorActive"];
        [fc.simulator setDelegate:nil];
    }
}

#pragma mark - Custom Methods

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isSimulatorActive"]) {
        self.isSimulatorOn = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [self updateSimulatorUI];
    }
}

-(void) updateSimulatorUI {
    if (!self.isSimulatorOn) {
        [self.simulatorButton setTitle:@"Start Simulator" forState:UIControlStateNormal];
        [self.simulatorStateLabel setHidden:YES];
    }
    else {
        [self.simulatorButton setTitle:@"Stop Simulator" forState:UIControlStateNormal];
    }
}

-(IBAction) onEnterVirtualStickControlButtonClicked:(id)sender
{
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    if (fc) {
        fc.yawControlMode = DJIVirtualStickYawControlModeAngularVelocity;
        fc.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
        
        WeakRef(target);
        [fc setVirtualStickModeEnabled:YES withCompletion:^(NSError * _Nullable error) {
            WeakReturn(target);
            if (error) {
                [DemoUtility showAlertViewWithTitle:nil message:[NSString stringWithFormat:@"Enter Virtual Stick Mode: %@", error.description] cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
            }
            else
            {
                [DemoUtility showAlertViewWithTitle:nil message:@"Enter Virtual Stick Mode:Succeeded" cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
            }

        }];
    }
    else
    {
        [DemoUtility showAlertViewWithTitle:nil message:@"Component not exist." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:self];
    }
}

-(IBAction) onExitVirtualStickControlButtonClicked:(id)sender
{
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    if (fc) {
        WeakRef(target);
        [fc setVirtualStickModeEnabled:NO withCompletion:^(NSError * _Nullable error) {
            WeakReturn(target);
            if (error){
                [DemoUtility showAlertViewWithTitle:nil message:[NSString stringWithFormat:@"Exit Virtual Stick Mode: %@", error.description] cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
            } else{
                [DemoUtility showAlertViewWithTitle:nil message:@"Exit Virtual Stick Mode:Succeeded" cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
            }
        }];
    }
    else
    {
        [DemoUtility showAlertViewWithTitle:nil message:@"Component not exist." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:self];

    }
}

- (IBAction)onSimulatorButtonClicked:(id)sender {
    
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];

    if (fc && fc.simulator) {
        if (!self.isSimulatorOn) {
            // The initial aircraft's position in the simulator.
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake(22, 113);
            WeakRef(target);
            [fc.simulator startWithLocation:location updateFrequency:20 GPSSatellitesNumber:10 withCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [DemoUtility showAlertViewWithTitle:nil message:[NSString stringWithFormat:@"Start simulator error: %@", error.description] cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];

                } else {
                    [DemoUtility showAlertViewWithTitle:nil message:@"Start Simulator succeeded." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
                }
            }];
        }
        else {
            WeakRef(target);
            [fc.simulator stopWithCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [DemoUtility showAlertViewWithTitle:nil message:[NSString stringWithFormat:@"Stop simulator error: %@", error.description] cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];

                } else {
                    [DemoUtility showAlertViewWithTitle:nil message:@"Stop Simulator succeeded." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
                }
            }];
        }
    }
}

-(IBAction) onTakeoffButtonClicked:(id)sender
{
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    if (fc) {
        WeakRef(target);
        [fc startTakeoffWithCompletion:^(NSError * _Nullable error) {
            WeakReturn(target);
            if (error) {
                [DemoUtility showAlertViewWithTitle:nil message:[NSString stringWithFormat:@"Takeoff: %@", error.description] cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
                
            } else {
                [DemoUtility showAlertViewWithTitle:nil message:@"Takeoff Success." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
                
            }
        }];
    }
    else
    {
        [DemoUtility showAlertViewWithTitle:nil message:@"Component not exist." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:self];
    }
}

- (IBAction)onLandButtonClicked:(id)sender {
    
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];

    if (fc) {
        WeakRef(target);
        [fc startLandingWithCompletion:^(NSError * _Nullable error) {
            WeakReturn(target);
            if (error) {
                [DemoUtility showAlertViewWithTitle:nil message:[NSString stringWithFormat:@"AutoLand : %@", error.description] cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];

            } else {
                [DemoUtility showAlertViewWithTitle:nil message:@"AutoLand Started." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:target];
            }
        }];
    }
    else
    {
        [DemoUtility showAlertViewWithTitle:nil message:@"Component not exist." cancelAlertAction:cancelAction defaultAlertAction:nil viewController:self];
    }
}

- (void)onStickChanged:(NSNotification*)notification
{
    NSDictionary *dict = [notification userInfo];
    NSValue *vdir = [dict valueForKey:@"dir"];
    CGPoint dir = [vdir CGPointValue];
    
    VirtualStickView* virtualStick = (VirtualStickView*)notification.object;
    if (virtualStick) {
        if (virtualStick == self.virtualStickLeft) {
            [self setThrottle:dir.y andYaw:dir.x];
        }
        else
        {
            [self setXVelocity:-dir.y andYVelocity:dir.x];
        }
    }
}

-(void) setThrottle:(float)y andYaw:(float)x
{
    self.mThrottle = y * -2;
    self.mYaw = x * 30;
    
    [self updateVirtualStick];
}

-(void) setXVelocity:(float)x andYVelocity:(float)y {
    self.mXVelocity = x * 15.0;
    self.mYVelocity = y * 15.0;
    [self updateVirtualStick];
}

-(void) updateVirtualStick
{
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = self.mYVelocity;
    ctrlData.roll = self.mXVelocity;
    ctrlData.yaw = self.mYaw;
    ctrlData.verticalThrottle = self.mThrottle;
    DJIFlightController* fc = [DemoUtility fetchFlightController];
    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
}

#pragma mark - DJI Simulator Delegate

- (void)simulator:(DJISimulator *_Nonnull)simulator didUpdateState:(DJISimulatorState *_Nonnull)state
{
    
   [self.simulatorStateLabel setHidden:NO];
   self.simulatorStateLabel.text = [NSString stringWithFormat:@"Yaw: %0.2f Pitch: %0.2f, Roll: %0.2f\n PosX: %0.2f PosY: %0.2f PosZ: %0.2f", state.yaw, state.pitch, state.roll, state.positionX, state.positionY, state.positionZ];
}

@end
