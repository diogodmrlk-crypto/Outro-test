#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScriptStore : NSObject
+ (instancetype)sharedStore;
- (NSArray<NSString *> *)allScriptNames;
- (nullable NSString *)loadScriptNamed:(NSString *)name error:(NSError **)error;
- (BOOL)saveScriptNamed:(NSString *)name
                content:(NSString *)content
                  error:(NSError **)error;
- (BOOL)deleteScriptNamed:(NSString *)name error:(NSError **)error;
- (NSURL *)scriptsDirectoryURL;
@end

NS_ASSUME_NONNULL_END
