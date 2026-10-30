#import "ScriptStore.h"

@implementation ScriptStore

+ (instancetype)sharedStore {
    static ScriptStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[ScriptStore alloc] init];
    });
    return store;
}

- (NSURL *)scriptsDirectoryURL {
    NSURL *documents = [[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory
               inDomains:NSUserDomainMask] firstObject];
    NSURL *directory = [documents URLByAppendingPathComponent:@"SporkScripts"
                                                  isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directory
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
    return directory;
}

- (NSString *)safeFilenameForName:(NSString *)name {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *base = [trimmed stringByDeletingPathExtension];
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:
                                @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ "]
                               invertedSet];
    base = [[base componentsSeparatedByCharactersInSet:invalid]
            componentsJoinedByString:@"_"];
    if (base.length == 0) base = @"NovoScript";
    return [base stringByAppendingPathExtension:@"luau"];
}

- (NSArray<NSString *> *)allScriptNames {
    NSArray<NSString *> *files = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:self.scriptsDirectoryURL.path error:nil];
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(NSString *item, NSDictionary *bindings) {
        return [[item.pathExtension lowercaseString] isEqualToString:@"luau"] ||
               [[item.pathExtension lowercaseString] isEqualToString:@"lua"];
    }];
    return [[files filteredArrayUsingPredicate:filter]
            sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (nullable NSString *)loadScriptNamed:(NSString *)name error:(NSError **)error {
    NSURL *url = [self.scriptsDirectoryURL URLByAppendingPathComponent:
                  [self safeFilenameForName:name]];
    return [NSString stringWithContentsOfURL:url
                                    encoding:NSUTF8StringEncoding
                                       error:error];
}

- (BOOL)saveScriptNamed:(NSString *)name content:(NSString *)content error:(NSError **)error {
    NSURL *url = [self.scriptsDirectoryURL URLByAppendingPathComponent:
                  [self safeFilenameForName:name]];
    return [content writeToURL:url
                    atomically:YES
                      encoding:NSUTF8StringEncoding
                         error:error];
}

- (BOOL)deleteScriptNamed:(NSString *)name error:(NSError **)error {
    NSURL *url = [self.scriptsDirectoryURL URLByAppendingPathComponent:
                  [self safeFilenameForName:name]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) return YES;
    return [[NSFileManager defaultManager] removeItemAtURL:url error:error];
}

@end
