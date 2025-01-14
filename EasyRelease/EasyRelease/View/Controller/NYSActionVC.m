//
//  NYSActionVC.m
//  EasyRelease
//
//  Created by 倪永胜 on 2021/2/19.
//  Copyright © 2021 NYS. All rights reserved.
//

#import "NYSActionVC.h"
#import "YYModel.h"
#import "NYSConfigModel.h"
#import "NYSAction.h"
#import "NYSShowTipViewControlle.h"
#import "NYSPanelWindow.h"

@interface NYSActionVC () <NSWindowDelegate>
{
    NSString *tempStr;
    NSPipe *outputPipe;
    NSTask *task;
}
@property (weak) IBOutlet NSButton *actionBtn;
@property (weak) IBOutlet NSPathControl *uploadPathControl;
@property (weak) IBOutlet NSPathControl *downloadPathControl;
@property (unsafe_unretained) IBOutlet NSTextView *actionInfoTextView;

@property (nonatomic, strong) NYSPanelWindow *panelWindow;
@property (nonatomic, strong) NSPopover *showTipPopover;

@end

@implementation NYSActionVC
- (NSPopover *)showTipPopover {
    if (!_showTipPopover) {
        _showTipPopover = [[NSPopover alloc] init];
        _showTipPopover.contentViewController = [[NYSShowTipViewControlle alloc] initWithNibName:@"NYSShowTipViewControlle" bundle:nil];
        _showTipPopover.behavior = NSPopoverBehaviorSemitransient;
    }
    return _showTipPopover;
}

- (NYSPanelWindow *)panelWindow {
    if (!_panelWindow) {
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"NYSPanelWindow" bundle:nil];
        NSArray *objects;
        if ([nib instantiateWithOwner:self topLevelObjects:&objects]) {
            for (id obj in objects) {
                if ([obj isKindOfClass:[NYSPanelWindow class]]) {
                    _panelWindow = obj;
                    break;
                }
            }
        }
        [_panelWindow center];
        _panelWindow.title = @"Config";
        _panelWindow.restorable = NO;
        _panelWindow.delegate = self;
    }
    return _panelWindow;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.actionInfoTextView.string = @"Hi ~\nEasy Release is already...";
//    self.actionInfoTextView.textColor = [NSColor colorWithRGBInt:ThemeColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ActionInfoNotificationHandler:) name:ActionInfoNotice object:nil];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
        self.view.wantsLayer = YES;
        [self.view setFrame:frameRect];
        [self.view.layer setBackgroundColor:[[NSColor clearColor] CGColor]];
    }
    return self;
}

- (void)handelConfig:(NYSConfigModel *)model url:(NSURL *)url {
    NSString *pnStr = url.path.lastPathComponent.stringByDeletingPathExtension;
    NSString *pPath = url.path.stringByDeletingLastPathComponent;
    if ([NYSUtils blankString:model.projectFileDirUrl.absoluteString]) {
        NSString *pfdStr = [[pPath stringByAppendingPathComponent:pnStr] stringByAppendingPathExtension:@"xcodeproj"];
        NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
        NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
        NSString *encodePfdStr = [pfdStr stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        model.projectFileDirUrl = [NSURL URLWithString:encodePfdStr];
    }
    if ([NYSUtils blankString:model.projectDirUrl.absoluteString]) {
        NSString *pdStr = [pPath stringByAppendingPathComponent:pnStr];
        NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
        NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
        NSString *encodePdStr = [pdStr stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        model.projectDirUrl = [NSURL URLWithString:encodePdStr];
    }
    
    if (model.isSasS) { // SasS环境下自动配置
        if (model.isAuto) {
            NSString *prefixStr = [NYSUtils generateRandomString:6];
            NSString *capitalStr = [NYSUtils getCapitalString:prefixStr];
            if (![NYSUtils blankString:model.projectNewName]) {
                capitalStr = [NYSUtils getCapitalString:model.projectNewName];
            }
            if ([NYSUtils blankString:model.projectNewName] && [NYSUtils blankString:model.projectOldName]) {
                model.projectOldName = pnStr;
                model.projectNewName = [NSString stringWithFormat:@"%@_%@", prefixStr, pnStr];
            } else if ([NYSUtils blankString:model.projectNewName] && ![NYSUtils blankString:model.projectOldName]) {
                model.projectNewName = [NSString stringWithFormat:@"%@_%@", prefixStr, model.projectOldName];
            } else if (![NYSUtils blankString:model.projectNewName] && [NYSUtils blankString:model.projectOldName]) {
                model.projectOldName = pnStr;
            }
            
            for (int i = 0; i < model.replaceArray.count; i++) {
                NYSReplaceModel *replace = model.replaceArray[i];
                if ([NYSUtils blankString:replace.nowPrefix] && ![NYSUtils blankString:replace.oldPrefix]) {
                    NSString *newValue = [NSString stringWithFormat:@"%@_%@", capitalStr, replace.oldPrefix];
                    if ([replace.type isEqual:@"global"]) {
                        newValue = [NSString stringWithFormat:@"%@_", capitalStr];
                    }
                    replace.nowPrefix = newValue;
                }
            }
        } else {
            // 手动配置
            self.panelWindow.oldProjectName = pnStr;
            [self.panelWindow makeKeyAndOrderFront:self];
        }
    }
    NConfig = model;
    
    // 发送刷新配置通知
    NSString *objStr = [NConfig yy_modelToJSONString];
    [[NSNotificationCenter defaultCenter] postNotificationName:RefreshConfNotice object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ActionInfoNotice object:objStr];
}

- (IBAction)uploadJsonFile:(NSButton *)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseFiles:YES];
    [oPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"json", nil]];
    if ([oPanel runModal] == NSModalResponseOK) {
        NSURL *url = [[oPanel URLs] objectAtIndex:0];
        _uploadPathControl.URL = url;
        NSString *str = [[NSString alloc] initWithData:[[NSData alloc] initWithContentsOfURL:url] encoding:NSUTF8StringEncoding];
        if ([NConfig yy_modelSetWithJSON:str]) {
            NYSConfigModel *model = [NYSConfigModel yy_modelWithJSON:str];
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            if (model.version.floatValue >= app_Version.floatValue) {
                [self handelConfig:model url:url];
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"Continue"];
                [alert addButtonWithTitle:@"Download"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert setAlertStyle:NSAlertStyleCritical];
                [alert setMessageText:@"Mismatched Config"];
                [alert setInformativeText:@"Mismatching config version numbers may cause an exception."];
                [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
                    if (returnCode == NSAlertFirstButtonReturn) {
                        [self handelConfig:model url:url];
                    } else if (returnCode == NSAlertSecondButtonReturn) {
                        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[ER_GH stringByAppendingString:@"/releases"]]];
                    } else {
                        NSLog(@"onclicked cancel");
                    }
                }];
            }
        } else {
            [ArtProgressHUD showErrorText:@"Mismatched format"];
        }
    }
}

- (IBAction)downloadJsonFile:(NSButton *)sender {
    if ([NYSUtils blankString:NConfig.projectFileDirUrl.path]) {
        [NYSUtils showAlertPanel:@"Missing project file parameter" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
    if ([NYSUtils blankString:NConfig.projectDirUrl.path]) {
        [NYSUtils showAlertPanel:@"Missing project Directory parameter" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setTitle:@"Save File"];
    [sPanel setMessage:@"Save Config Json File"];
    [sPanel setPrompt:NULL];
    [sPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"json", nil]];
    [sPanel setCanCreateDirectories:YES];
    [sPanel setCanSelectHiddenExtension:YES];
    [sPanel setNameFieldStringValue:NConfig.projectFileDirUrl.path.lastPathComponent.stringByDeletingPathExtension];
    NSString *pPath = NConfig.projectFileDirUrl.absoluteString.stringByDeletingLastPathComponent;
    [sPanel setDirectoryURL:[NSURL URLWithString:pPath]];
    
    __block NSString *chooseFile;
    [sPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            chooseFile = [[sPanel URL] path];
            self->_downloadPathControl.URL = [sPanel URL];
            NSData *data = [NConfig yy_modelToJSONData];
            [data writeToFile:chooseFile atomically:YES];
            [ArtProgressHUD showSuccessText:@"save success"];
            NSLog(@"Click OK Choose files : %@",chooseFile);
        } else if (result == NSModalResponseCancel)
            NSLog(@"Click cancle");
    }];
}

- (IBAction)action:(NSButton *)sender {
    // 项目配置校验
    if ([NYSUtils blankString:NConfig.projectFileDirUrl.path]) {
        [NYSUtils showAlertPanel:@"Missing project file parameter" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
    if ([NYSUtils blankString:NConfig.projectDirUrl.path]) {
        [NYSUtils showAlertPanel:@"Missing project Directory parameter" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:NConfig.projectFileDirUrl.path]) {
        [NYSUtils showAlertPanel:@"Project file inexistence" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
    BOOL isDirectory = NO;
    [fm fileExistsAtPath:NConfig.projectDirUrl.path isDirectory:&isDirectory];
    if (!isDirectory) {
        [NYSUtils showAlertPanel:@"Project directory inexistence" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
#pragma mark -FIX 检查路径中是否包含空格
    if ((NConfig.isRehashImages || NConfig.isAutoPodInstall) && ([NConfig.projectFileDirUrl.path.stringByDeletingLastPathComponent rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].length > 0)) {
        [NYSUtils showAlertPanel:@"The project path contains Spaces. \ndelete spaces \nor \nclose Rehash images \nclose Auto pod install" forWindow:self.view.window completionHandler:nil];
        return;
    }
    
    // action go go go...
    @try {
        [sender setEnabled:NO];
        
        NYSAction *action = [[NYSAction alloc] initWithConfig:NConfig];
        [action action];
        [ArtProgressHUD showSuccessText:@"ER Finish"];
    } @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ActionInfoNotice object:exception.reason];
        [ArtProgressHUD showErrorText:@"ER Error"];
    } @finally {
        [sender setEnabled:YES];
    }
}

- (IBAction)tip:(NSButton *)sender {
    [self.showTipPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMinY];
}

- (void)ActionInfoNotificationHandler:(NSNotification *)notification {
    NSString *newOutput = notification.object;
    
    NSString *previousOutput = self.actionInfoTextView.string;
    NSString *nextOutput = [NSString stringWithFormat:@"%@\n%@", previousOutput, newOutput];
    self.actionInfoTextView.string = nextOutput;
    // 滚动到可视位置
    NSRange range = {nextOutput.length, 0};
    [self.actionInfoTextView scrollRangeToVisible:range];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ActionInfoNotice object:nil];
}

@end
