//
//  WiFiEvidenceSource.m
//  MarcoPolo
//
//  Created by David Symonds on 29/03/07.
//

#import <CoreWLAN/CoreWLAN.h>
#import "WiFiEvidenceSource.h"

@implementation NSString (LeftPadding)

- (NSString *) stringByPaddingTheLeftToLength:(NSUInteger) newLength 
								   withString:(NSString *) padString 
							  startingAtIndex:(NSUInteger) padIndex
{
    if ([self length] <= newLength)
        return [[@"" stringByPaddingToLength:newLength - [self length] 
								  withString:padString 
							 startingAtIndex:padIndex] 
				stringByAppendingString:self];
    else
        return [[self copy] autorelease];
}

@end

@implementation WiFiEvidenceSource

- (id)init
{
	if (!(self = [super init]))
		return nil;

	lock = [[NSLock alloc] init];
	apList = [[NSMutableArray alloc] init];
	wakeUpCounter = 0;

	return self;
}

- (void)dealloc
{
	[lock release];
	[apList release];

	[super dealloc];
}

- (void)wakeFromSleep:(id)arg
{
	[super wakeFromSleep:arg];

	wakeUpCounter = 2;
}

static NSString *macToString(const UInt8 *mac)
{
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
		mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]];
}

- (void)doUpdate
{
	NSMutableArray *all_aps = [NSMutableArray array];

	NSArray *wifs = [CWInterface supportedInterfaces];
	if ([wifs count]) {
		CWInterface *wif = [CWInterface interfaceWithName: [wifs objectAtIndex:0]];
		if (wif) {
			// NSString *bssid_to_skip = nil;
			
			if (kCWInterfaceStateRunning == [[wif interfaceState] intValue]) {
				NSString *ssid = [wif ssid];
				NSString *bssid = [[wif bssid] stringByPaddingTheLeftToLength: 17 withString: @"0" startingAtIndex: 0];
				
				// bssid_to_skip = bssid;
				[all_aps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									ssid, @"SSID", bssid, @"MAC", nil]];
			} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"WiFiAlwaysScans"] ||
					   wakeUpCounter-- > 0) {
				NSArray *scanResults = [wif scanForNetworksWithParameters: nil error: nil];
				if (scanResults && [scanResults count]) {
					NSEnumerator *en = [scanResults objectEnumerator];
					CWNetwork *net = nil;
					while ((net = [en nextObject])) {
						NSString *ssid = [net ssid];
						NSString *bssid = [[net bssid] stringByPaddingTheLeftToLength: 17 withString: @"0" startingAtIndex: 0];
						
						[all_aps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											ssid, @"SSID", bssid, @"MAC", nil]];
					}
				}
			}
		}
	}

	[lock lock];
	[apList setArray:all_aps];
	[self setDataCollected:[apList count] > 0];
#ifdef DEBUG_MODE
	NSLog(@"%@ >> %@", [self class], apList);
#endif
	[lock unlock];
	
}

- (void)clearCollectedData
{
	[lock lock];
	[apList removeAllObjects];
	[self setDataCollected:NO];
	[lock unlock];
}

- (NSString *)name
{
	return @"WiFi";
}

- (NSArray *)typesOfRulesMatched
{
	return [NSArray arrayWithObjects:@"MAC", @"SSID", nil];
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule
{
	BOOL match = NO;
	NSString *key = [rule valueForKey:@"type"];
	NSString *param = [rule valueForKey:@"parameter"];

	[lock lock];
	NSEnumerator *en = [apList objectEnumerator];
	NSDictionary *dict;
	while ((dict = [en nextObject])) {
		NSString *x = [dict valueForKey:key];
		if ([param isEqualToString:x]) {
			match = YES;
			break;
		}
	}
	[lock unlock];

	return match;
}

- (NSString *)getSuggestionLeadText:(NSString *)type
{
	if ([type isEqualToString:@"MAC"])
		return NSLocalizedString(@"A WiFi access point with a MAC of", @"In rule-adding dialog");
	else
		return NSLocalizedString(@"A WiFi access point with an SSID of", @"In rule-adding dialog");
}

- (NSArray *)getSuggestions
{
	NSMutableArray *arr = [NSMutableArray array];
	NSEnumerator *en;
	NSDictionary *dict;

	[lock lock];

	en = [apList objectEnumerator];
	while ((dict = [en nextObject])) {
		NSString *mac = [dict valueForKey:@"MAC"], *ssid = [dict valueForKey:@"SSID"];
		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			@"MAC", @"type",
			mac, @"parameter",
			[NSString stringWithFormat:@"%@ (%@)", mac, ssid], @"description", nil]];
		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			@"SSID", @"type",
			ssid, @"parameter",
			ssid, @"description", nil]];
	}

	[lock unlock];

	return arr;
}

@end
