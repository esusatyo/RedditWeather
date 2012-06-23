//
//  YahooWeather.m
//  RedditWeather
//
//  Created by Mathieu Hendey on 23/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#import "YahooWeather.h"

@implementation YahooWeather
@synthesize locationManager, currentLocation, latitude, longitude, weatherData;

- (void) getWeather {
    
    // Create the locationManager, set its delegate to self and start it updating.
    self.locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    // Get location and then call didUpdateToLocation to update location and start pulling weather data
    [locationManager startUpdatingLocation];
    NSLog(@"asd");
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"asda");
    // Called when new location data, such as better accuracy for a location or if the device moves.
    [locationManager stopUpdatingLocation];
    self.currentLocation = newLocation;
    latitude = currentLocation.coordinate.latitude;
    longitude = currentLocation.coordinate.longitude;
    
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            NSString *townString = [placemark locality];  // Returns the current town.
        }    
    }];
    
    // Show the spinning wheel (UIActivityIndicator) in the status bar whilst we're getting the data.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // URL for dataWithContentsOfURL.
    NSString *urlString = [NSString stringWithFormat:@"http://where.yahooapis.com/geocode?location=%f+%f&flags=J&gflags=r&appid=83Q_GxzV34GmB4fZFHAlkt1NOa6YN3.BJ2iyaYv.LeW8uWaUVc0jLJYEISsQdUUVIhoHGw--", latitude, longitude];
    
    // Get weather data in background queue so UI doesn't lock up.
    dispatch_async(kBgQueue, ^{
        NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString:urlString]];
        [self performSelectorOnMainThread:@selector(fetchedData:)
                               withObject:data waitUntilDone:YES];
    });
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // Called if Core Location reports an error. This method is optional, but good habit to include.
    
    // Create and display a UIAlertView if an error occurs.
    if(error.code == kCLErrorDenied) {
        [locationManager stopUpdatingLocation];
    } else if(error.code == kCLErrorLocationUnknown) {
        // retry
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)fetchedData:(NSData *)responseData {    
    
    NSError *error;
    // Get the JSON object from Yahoo.
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    NSDictionary* resultset = [json objectForKey:@"ResultSet"];
    NSArray* results = [resultset objectForKey:@"Results"];
    NSDictionary* rawPlaceData = [results objectAtIndex:0];
    
    // When we've got the data, remove the UIActivityIndicator from the status bar.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // URL for dataWithContentsOfURL.
    NSString * urlString = [NSString stringWithFormat: @"http://weather.yahooapis.com/forecastjson?u=c&w=%@", [rawPlaceData objectForKey:@"woeid"]];
    
    NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString:urlString]];
    [self performSelectorOnMainThread:@selector(fetchedWeather:)
                           withObject:data waitUntilDone:YES];
}

- (void)fetchedWeather:(NSData *)responseData {
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
}

@end