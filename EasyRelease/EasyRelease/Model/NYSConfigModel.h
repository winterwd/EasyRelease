//
//  NYSConfigModel.h
//  EasyRelease
//
//  Created by 倪永胜 on 2021/2/20.
//  Copyright © 2021 NYS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ReplaceType_Global,
    ReplaceType_Class,
    ReplaceType_Method,
} ReplaceType;

typedef enum : NSUInteger {
    IgnoreType_Directory,
    IgnoreType_Class,
    IgnoreType_File,
} IgnoreType;

@interface NYSReplaceModel : NSObject
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *oldPrefix;
@property (nonatomic, copy) NSString *nowPrefix;
@property (nonatomic, assign) ReplaceType type_e;
@property (nonatomic) BOOL enable;
@end

@interface NYSIgnoreModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) IgnoreType type_e;
@property (nonatomic) BOOL enable;
@end

@interface NYSConfigModel : NSObject
@property (nonatomic, strong) NSURL *projectFileDirUrl;
@property (nonatomic, strong) NSURL *projectDirUrl;
@property (nonatomic, strong) NSMutableArray<NYSReplaceModel *> *replaceArray;
@property (nonatomic, strong) NSMutableArray<NYSIgnoreModel *> *ignoreArray;
@property (nonatomic, strong) NSString *projectOldName;
@property (nonatomic, strong) NSString *projectNewName;
@property (nonatomic, assign) BOOL isDelAnnotation;
@property (nonatomic, assign) BOOL isRehashImages;
@property (nonatomic, assign) BOOL isAutoPodInstall;
@property (nonatomic, assign) BOOL isAuto;
@property (nonatomic, assign) BOOL isSasS;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *desc;
@end

NS_ASSUME_NONNULL_END
