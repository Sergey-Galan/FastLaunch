

#import "FastLaunchJob.h"

@interface FastLaunchJob()
@end

@implementation FastLaunchJob

- (instancetype)initWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr {
    self = [super init];
    if (self) {
        _arguments = args;
        _standardInputString = stdinStr;
    }
    return self;
}

+ (instancetype)jobWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr {
    return [[self alloc] initWithArguments:args andStandardInput:stdinStr];
}

@end
