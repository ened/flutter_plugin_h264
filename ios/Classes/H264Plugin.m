#import "H264Plugin.h"
#import <Foundation/Foundation.h>

#if __has_include(<h264/h264-Swift.h>)
#import <h264/h264-Swift.h>
#else
#import "h264-Swift.h"
#endif


@interface H264Plugin() {
    dispatch_queue_t queue;
    H264Reader *reader;
}

@end

@implementation H264Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"asia.ivity.flutter/h264"
                                     binaryMessenger:[registrar messenger]];
    H264Plugin* instance = [[H264Plugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    if (self = [super init]) {
        queue = dispatch_queue_create("h264 decoder", nil);
        reader = [[H264Reader alloc] init];
    }
    
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"decode" isEqualToString:call.method]) {
        NSDictionary *params = call.arguments;
        [self handleDecode:params result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleDecode:(NSDictionary*)params result:(FlutterResult)result {
//    dispatch_async(queue, ^{
        NSURL *source = [NSURL URLWithString:params[@"source"]];
        NSURL *target = [NSURL URLWithString:params[@"target"]];
        NSError *error;
        [self->reader loadWithUrl:source error:&error];
        if (error) {
            result([FlutterError errorWithCode:@"h264" message:nil details:nil]);
            return;
        }
        if (@available(iOS 9.0, *)) {
            [self->reader convertWithTarget:target error:&error];
        } else {
            result([FlutterError errorWithCode:@"h264" message:@"unavailable" details:nil]);
        }
        if (error) {
            result([FlutterError errorWithCode:@"h264" message:[error localizedDescription] details:nil]);
        } else {
            result(target.absoluteString);
        }
//    });

}

@end
