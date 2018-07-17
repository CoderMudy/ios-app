#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXNFastURLDetector : NSObject

- (void)enumerateMatchesInAttributedString:(NSAttributedString *)attributedString options:(NSMatchingOptions)options usingBlock:(void (NS_NOESCAPE ^)(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
