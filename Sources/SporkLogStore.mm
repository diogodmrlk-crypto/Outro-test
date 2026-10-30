#import "SporkLogStore.h"

static NSMutableArray<NSString *> *s_logs;
static dispatch_queue_t s_logQueue;
static const NSUInteger kMaximumLogEntries = 500;

static void ensureLogStore(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_logs = [NSMutableArray array];
        s_logQueue = dispatch_queue_create("com.spork.logs", DISPATCH_QUEUE_SERIAL);
    });
}

NSArray<NSString *> *SporkLogSnapshot(void) {
    ensureLogStore();
    __block NSArray *snapshot;
    dispatch_sync(s_logQueue, ^{
        snapshot = [s_logs copy];
    });
    return snapshot;
}

void SporkLogAppend(NSString *message) {
    ensureLogStore();
    NSString *safe = message ?: @"(log vazio)";
    dispatch_async(s_logQueue, ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        NSString *entry = [NSString stringWithFormat:@"[%@] %@",
                           [formatter stringFromDate:[NSDate date]], safe];
        [s_logs addObject:entry];
        if (s_logs.count > kMaximumLogEntries) {
            [s_logs removeObjectsInRange:NSMakeRange(0, s_logs.count - kMaximumLogEntries)];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:@"SporkLogUpdated" object:nil];
        });
    });
}

void SporkLogClear(void) {
    ensureLogStore();
    dispatch_async(s_logQueue, ^{
        [s_logs removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:@"SporkLogUpdated" object:nil];
        });
    });
}
