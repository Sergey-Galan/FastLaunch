

#import <Foundation/Foundation.h>

@interface FastLaunchJob : NSObject

@property (nonatomic, copy) NSArray *arguments;
@property (nonatomic, copy) NSString *standardInputString;

- (instancetype)initWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr;
+ (instancetype)jobWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr;

@end
