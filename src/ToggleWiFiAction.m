//
//  ToggleWiFiAction.m
//  MarcoPolo
//
//  Created by David Symonds on 2/05/07.
//

#import <CoreWLAN/CoreWLAN.h>
#import "ToggleWiFiAction.h"


@implementation ToggleWiFiAction

- (NSString *)description
{
	if (turnOn)
		return NSLocalizedString(@"Turning WiFi on.", @"");
	else
		return NSLocalizedString(@"Turning WiFi off.", @"");
}

- (BOOL)execute:(NSString **)errorString
{
	NSArray *wifs = [CWInterface supportedInterfaces];
	if ([wifs count]) {
		CWInterface *wif = [CWInterface interfaceWithName: [wifs objectAtIndex:0]];
		if (wif && [wif setPower:turnOn error: nil]) return YES;
	}
	
	if (turnOn)
		*errorString = NSLocalizedString(@"Failed turning WiFi on.", @"");
	else
		*errorString = NSLocalizedString(@"Failed turning WiFi off.", @"");
	
	return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for ToggleWiFi actions is either \"1\" "
				 "or \"0\", depending on whether you want your WiFi "
				 "turned on or off.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Turn WiFi", @"Will be followed by 'on' or 'off'");
}

@end
