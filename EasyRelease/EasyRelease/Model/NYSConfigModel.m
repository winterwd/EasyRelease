//
//  NYSConfigModel.m
//  EasyRelease
//
//  Created by 倪永胜 on 2021/2/20.
//  Copyright © 2021 NYS. All rights reserved.
//

#import "NYSConfigModel.h"
#import "YYModel.h"

@implementation NYSReplaceModel
- (void)setType:(NSString *)type
{
    _type = type;
    if ([type isEqualToString:@"class"]) {
        _type_e = ReplaceType_Class;
    }
    else if ([type isEqualToString:@"method"]) {
        _type_e = ReplaceType_Method;
    }
    else if ([type isEqualToString:@"global"]) {
        _type_e = ReplaceType_Global;
    }
}
@end
@implementation NYSIgnoreModel
- (void)setType:(NSString *)type
{
    _type = type;
    if ([type isEqualToString:@"directory"]) {
        _type_e = IgnoreType_Directory;
    }
    else if ([type isEqualToString:@"file"]) {
        _type_e = IgnoreType_File;
    }
    else if ([type isEqualToString:@"class"]) {
        _type_e = IgnoreType_Class;
    }
}
@end
@implementation NYSConfigModel
- (NSUInteger)hash {
    return [self yy_modelHash];
}

- (BOOL)isEqual:(id)object {
 return [self yy_modelIsEqual:object];
}

/// 自定义model转换
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    NSString *pfd = dic[@"projectFileDirUrl"];
    NSString *pd = dic[@"projectDirUrl"];
    if (![pfd isKindOfClass:[NSString class]] || ![pd isKindOfClass:[NSString class]]) return NO;
    NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    _projectFileDirUrl = [NSURL URLWithString:[pfd stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters]];
    _projectDirUrl = [NSURL URLWithString:[pd stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters]];
    return YES;
}

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    NSString *version = dic[@"version"];
    NSString *desc = dic[@"desc"];
    if (![version isKindOfClass:[NSString class]] || ![desc isKindOfClass:[NSString class]]) return NO;
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    dic[@"version"] = app_Version;
    dic[@"desc"] = ER_GH;
    return YES;
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"replaceArray" : [NYSReplaceModel class],
             @"ignoreArray" : NYSIgnoreModel.class };
}
@end
