//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "OWSGroupAvatarBuilder.h"
#import "OWSContactsManager.h"
#import "TSGroupThread.h"
#import <SignalCoreKit/NSData+OWS.h>
#import <SignalMessaging/SignalMessaging-Swift.h>
#import <SignalServiceKit/SSKEnvironment.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSGroupAvatarBuilder ()

@property (nonatomic, readonly) TSGroupThread *thread;
@property (nonatomic, readonly) NSUInteger diameter;

@end

@implementation OWSGroupAvatarBuilder

- (instancetype)initWithThread:(TSGroupThread *)thread diameter:(NSUInteger)diameter
{
    self = [super init];
    if (!self) {
        return self;
    }

    _thread = thread;
    _diameter = diameter;

    return self;
}

#pragma mark -

- (nullable UIImage *)buildSavedImage
{
    return self.thread.groupModel.groupAvatarImage;
}

- (nullable UIImage *)buildSavedImageWithTransaction:(SDSAnyReadTransaction *)transaction
{
    return self.thread.groupModel.groupAvatarImage;
}

- (nullable UIImage *)buildDefaultImage
{
    UIColor *avatarColor = [ChatColors avatarColorForThread:self.thread];
    return [self.class defaultAvatarForGroupId:self.thread.groupModel.groupId
                                      diameter:self.diameter];
}

+ (nullable UIImage *)defaultAvatarForGroupId:(NSData *)groupId
                                     diameter:(NSUInteger)diameter
{
    UIColor *avatarColor = [ChatColors avatarColorForGroupId:groupId];
    NSString *cacheKey = [NSString
        stringWithFormat:@"%@-%d-%lu", groupId.hexadecimalString, Theme.isDarkThemeEnabled, (unsigned long)diameter];

    UIImage *_Nullable cachedAvatar =
        [OWSGroupAvatarBuilder.contactsManagerImpl getImageFromAvatarCacheWithKey:cacheKey diameter:(CGFloat)diameter];
    if (cachedAvatar) {
        return cachedAvatar;
    }

    UIImage *_Nullable image = [OWSGroupAvatarBuilder groupAvatarImageWithBackgroundColor:avatarColor
                                                                                 diameter:diameter];
    if (!image) {
        OWSFailDebug(@"Could not create group avatar.");
        return nil;
    }

    [OWSGroupAvatarBuilder.contactsManagerImpl setImageForAvatarCache:image forKey:cacheKey diameter:diameter];
    return image;
}

+ (nullable UIImage *)groupAvatarImageWithBackgroundColor:(UIColor *)backgroundColor diameter:(NSUInteger)diameter
{
    UIImage *icon = [UIImage imageNamed:@"group-outline-256"];
    // Adjust asset size to reflect the output diameter.
    CGFloat scaling = diameter * 0.003f;
    CGSize iconSize = CGSizeScale(icon.size, scaling);
    return [OWSAvatarBuilder avatarImageWithIcon:icon
                                        iconSize:iconSize
                                 backgroundColor:backgroundColor
                                        diameter:diameter];
}

@end

NS_ASSUME_NONNULL_END
