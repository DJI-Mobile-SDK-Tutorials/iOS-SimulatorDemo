//
//  DemoUtility.m
//  DJISimulatorDemo
//
//  Created by DJI on 8/6/2016.
//  Copyright © 2016 DJI. All rights reserved.
//

#import "DemoUtility.h"
#import <DJISDK/DJISDK.h>

@implementation DemoUtility

+(DJIBaseProduct*) fetchProduct {
    return [DJISDKManager product];
}

+(DJIAircraft*) fetchAircraft {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]);
    }
    
    return nil;
}

+(DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    
    return nil;
}

+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message cancelAlertAction:(UIAlertAction*)cancelAlert defaultAlertAction:(UIAlertAction*)defaultAlert viewController:(UIViewController *)viewController{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if (cancelAlert) {
        [alertController addAction:cancelAlert];
    }
    
    if (defaultAlert) {
        [alertController addAction: defaultAlert];
    }
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end
