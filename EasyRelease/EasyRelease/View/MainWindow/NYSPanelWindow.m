//
//  NYSPanelWindow.m
//  EasyRelease
//
//  Created by niyongsheng on 2021/3/3.
//  Copyright © 2021 NYS. All rights reserved.
//

#import "NYSPanelWindow.h"
#import "YYModel.h"

@interface NYSPanelWindow ()
@property (weak) IBOutlet NSTextField *projectNameField;

@end

@implementation NYSPanelWindow

- (IBAction)okOnclicked:(NSButtonCell *)sender {
    if ([NYSUtils blankString:_projectNameField.stringValue]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ActionInfoNotice object:@"\nnull value\n"];
        return;
    }
    
    [self close];
    
    NSString *prefixStr = _projectNameField.stringValue;
    NSString *capitalStr = [NYSUtils getCapitalString:prefixStr];
    if (![NYSUtils blankString:NConfig.projectNewName]) {
        capitalStr = [NYSUtils getCapitalString:NConfig.projectNewName];
    }
    if ([NYSUtils blankString:NConfig.projectNewName] && [NYSUtils blankString:NConfig.projectOldName]) {
        NConfig.projectOldName = _oldProjectName;
        NConfig.projectNewName = prefixStr;
    } else if ([NYSUtils blankString:NConfig.projectNewName] && ![NYSUtils blankString:NConfig.projectOldName]) {
        NConfig.projectNewName = prefixStr;
    } else if (![NYSUtils blankString:NConfig.projectNewName] && [NYSUtils blankString:NConfig.projectOldName]) {
        NConfig.projectOldName = _oldProjectName;
    }
    
    for (int i = 0; i < NConfig.replaceArray.count; i++) {
        NYSReplaceModel *replaceDict = NConfig.replaceArray[i];
        if ([NYSUtils blankString:replaceDict.nowPrefix] && ![NYSUtils blankString:replaceDict.oldPrefix]) {
            NSString *newValue = [NSString stringWithFormat:@"%@_%@", capitalStr, replaceDict.oldPrefix];
            if (replaceDict.type_e == ReplaceType_Global) {
                newValue = [NSString stringWithFormat:@"%@_", capitalStr];
            }
            replaceDict.nowPrefix = newValue;
        }
    }
    
    // 发送刷新配置通知
    NSString *objStr = [NConfig yy_modelToJSONString];
    [[NSNotificationCenter defaultCenter] postNotificationName:RefreshConfNotice object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ActionInfoNotice object:objStr];
}

@end
