//
//  XYPageMaster.m
//  XYPageMaster
//
//  Created by lizitao on 2018/5/4.
//

#import "XYPageMaster.h"

@interface XYPageMaster ()
@property (nonatomic, strong) XYPageMasterNavigationController *rootNavigationController;
@property (nonatomic, strong) NSString *urlScheme;
@property (nonatomic, strong) NSString *fileNamesOfURLMapping;
@property (nonatomic, strong) NSString *rootVCName;
@property (nonatomic, strong) NSString *rootVC_SB;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray *>*urlMapping;
@end

@implementation XYPageMaster

static XYPageMaster *master;
static dispatch_once_t onceToken;
@synthesize urlScheme = _urlScheme;
@synthesize fileNamesOfURLMapping = _fileNamesOfURLMapping;

+ (instancetype)master
{
    return [[self alloc] init];
}

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    dispatch_once(&onceToken, ^{
        master = [super allocWithZone:zone];
    });
    return master;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return master;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone
{
    return master;
}

- (void)setFileNamesOfURLMapping:(NSString *)fileName
{
    _fileNamesOfURLMapping = fileName;
    [self loadViewControllerElements];
}

- (void)setupNavigationControllerWithParams:(NSDictionary *)params
{
    //eg: params = @{@"schema":@"xiaoying",@"pagesFile":@"urlmapping",@"rootVC":@"XYHomeTabBarVC",@"rootVC_SB":@"Main"};
    if (!params) return;
    self.urlScheme = [params objectForKey:@"schema"];
    if (self.urlScheme.length < 1) return;
    self.fileNamesOfURLMapping = [params objectForKey:@"pagesFile"];
    if (self.fileNamesOfURLMapping.length < 1) return;
    self.rootVCName = [params objectForKey:@"rootVC"];
    if (self.rootVCName.length < 1) return;
    //storyboard信息
    self.rootVC_SB = [params objectForKey:@"rootVC_SB"];
    [self setupRootNavigationController];
}

- (void)setupRootNavigationController
{
    if (!self.rootNavigationController) {
        UIViewController *homeViewController = nil;
        if (self.rootVC_SB.length > 0) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:self.rootVC_SB bundle:nil];
            homeViewController = [storyBoard instantiateViewControllerWithIdentifier:self.rootVCName];
        } else {
            homeViewController = [[NSClassFromString(self.rootVCName) alloc]init];
        }
        _rootNavigationController = [[XYPageMasterNavigationController alloc] initWithRootViewController:homeViewController];
    }
    [[XYPageMaster master] setNavigationController:self.rootNavigationController];
}

- (void)resetNavigationController
{
     self.rootNavigationController = nil;
     [self setupRootNavigationController];
     [[XYPageMaster master] setNavigationController:self.rootNavigationController];
}

- (void)setNavigationController:(XYPageMasterNavigationController *)navigationContorller
{
    _navigationContorller = navigationContorller;
}

- (NSMutableDictionary *)loadViewControllerElements
{
    if (_urlMapping) {
        [_urlMapping removeAllObjects];
    } else {
        _urlMapping = [NSMutableDictionary dictionary];
    }
    
    NSString *fileName = self.fileNamesOfURLMapping;
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (content) {
        NSArray *eachLine = [content componentsSeparatedByString:@"\n"];
        for (NSString *aString in eachLine) {
            if (aString.length < 1) {
                NSLog(@"空行");
                continue;
            }
            NSString *lineString = [aString stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (lineString.length < 1) {
                //空行
                continue;
            }
            NSRange commentRange = [lineString rangeOfString:@"#"];
            if (commentRange.location == 0) {
                // #在开头，表明这一行是注释
                continue;
            }
            if (commentRange.location != NSNotFound) {
                //其后有注释，需要去除后面的注释
                lineString = [lineString substringToIndex:commentRange.location];
            }
            NSRange tabRange = [lineString rangeOfString:@"\t"];
            BOOL isContainTabT = NO;
            if (tabRange.location != NSNotFound) {
                isContainTabT = YES;
                //过滤文本编辑器中\t\t\t\t\t
                lineString = [lineString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
            }
            if ([lineString rangeOfString:@":"].location != NSNotFound) {
                NSString *omitString = [lineString stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSArray *kv = [omitString componentsSeparatedByString:@":"];
                //key值一律字母小写
                if (kv.count == 2) {
                    NSString *host = [kv[0] lowercaseString];
                    NSArray *array = [NSArray arrayWithObjects:kv[1],nil];
                    [_urlMapping setObject:array forKey:host];
                }
                if (kv.count == 3) {
                    NSString *host = [kv[0] lowercaseString];
                    NSArray *array = [NSArray arrayWithObjects:kv[1], kv[2], nil];
                    [_urlMapping setObject:array forKey:host];
                }
                if (kv.count == 4) {
                    NSString *host = [kv[0] lowercaseString];
                    NSArray *array = [NSArray arrayWithObjects:kv[1], kv[2], kv[3], nil];
                    [_urlMapping setObject:array forKey:host];
                }
            }
        }
    } else {
        NSLog(@"[url mapping error] file(%@) is empty!!!!", fileName);
    }
    return _urlMapping;
}

- (void)openURLAction:(XYUrlAction *)urlAction result:(void(^)(NSString *viewController))result
{
    if (![urlAction isKindOfClass:[XYUrlAction class]]) return;
    NSString *viewController = [self obtainClassFromURLAction:urlAction];
    if (result) {
        result(viewController);
    }
}

- (void)openUrl:(NSString *)url action:(void(^)(XYUrlAction *action))actionBlock
{
    if (url.length <= 0) return;
    XYUrlAction *action = [XYUrlAction actionWithURL:[NSURL URLWithString:url]];
    if (actionBlock) {
        actionBlock(action);
    }
    if (!self.navigationContorller) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleOpenURLAction:action];
    });
}

- (void)openURLAction:(XYUrlAction *)urlAction
{
    if (![urlAction isKindOfClass:[XYUrlAction class]]) return;
    if (!self.navigationContorller) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleOpenURLAction:urlAction];
    });
}

- (UIViewController *)handleOpenURLAction:(XYUrlAction *)urlAction
{
    return [self obtainControllerURLAction:urlAction];
}

- (UIViewController *)obtainControllerURLAction:(XYUrlAction *)urlAction
{
    UIViewController *controller = nil;
    
    NSString *key = [self obtainKeyFromURLAction:urlAction];
    if (key.length < 1) return nil;
    NSArray *array = [_urlMapping objectForKey:key];
   
    //storyboard跳转，默认mainBundle中
    if (array.count == 2) {
        NSString *storyboardName = array.lastObject;
        if (storyboardName.length > 0) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:[NSBundle mainBundle]];
            NSString *class = [self obtainClassFromURLAction:urlAction];
            if (class.length < 1) return nil;
            controller = [storyboard instantiateViewControllerWithIdentifier:class];
        }
    }
    //storyboard跳转，自定义Bundle中
    if (array.count == 3) {
        NSString *storyboardName = array[1];
        NSString *bundleName = array.lastObject;;
        if (storyboardName.length > 0 && bundleName.length > 0) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
            NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
            NSString *class = [self obtainClassFromURLAction:urlAction];
            if (class.length < 1) return nil;
            controller = [storyboard instantiateViewControllerWithIdentifier:class];
        }
    }
    //非storyboard
    if (array.count == 1) {
        NSString *class = [self obtainClassFromURLAction:urlAction];
        controller = [NSClassFromString(class) new];
    }
    
    if (!controller) return nil;
    BOOL isSingleton = NO;
    if ([[controller class] respondsToSelector:@selector(isSingleton)]) {
        isSingleton = [[controller class] isSingleton];
    }
    XYSingletonType singletonType = urlAction.singletonType;
    if (isSingleton && singletonType != XYSingletonTypeNone) {
        [self pushSingletonViewController:controller withURLAction:urlAction];
    } else {
        [self openViewController:controller withURLAction:urlAction];
    }
    return controller;
}

- (NSString *)obtainClassFromURLAction:(XYUrlAction *)urlAction
{
    if (urlAction.url.host.length < 1) return nil;
    NSString *class = nil;
    NSArray *array = [_urlMapping objectForKey:[urlAction.url.host lowercaseString]];
    if (array.count >= 1) {
        class = array.firstObject;
    }
    if (class.length < 1) return nil;
    return class;
}

- (NSString *)obtainKeyFromURLAction:(XYUrlAction *)urlAction
{
    NSString *key = [urlAction.url.host lowercaseString];
    if (key.length < 1) return nil;
    return key;
}

- (BOOL)checkUrlIsRegistered:(NSURL *)url
{
    if (!url) return NO;
    if (![url.scheme isEqualToString:_urlScheme]) return NO;
    if (url.host.length > 0) {
        if ([_urlMapping objectForKey:url.host]) {
            return YES;
        }
    }
    return NO;
}

- (void)openViewController:(UIViewController *)controller withURLAction:(XYUrlAction *)urlAction
{
    if ([controller respondsToSelector:@selector(handleWithURLAction:)]) {
        [controller handleWithURLAction:urlAction];
    }
    [self pushViewController:controller withURLAction:urlAction];
}

- (void)pushViewController:(UIViewController *)controller withURLAction:(XYUrlAction *)urlAction
{
    if (!urlAction.naviTransition) {
         [self.navigationContorller pushViewController:controller withAnimation:urlAction.animation == XYNaviAnimationPush];
    } else {
         [self.navigationContorller pushViewController:controller withTransition:urlAction.naviTransition];
    }
}

- (void)pushSingletonViewController:(UIViewController *)controller withURLAction:(XYUrlAction *)urlAction
{
    if (!controller) return;
    NSArray<UIViewController *> *viewControllers = self.navigationContorller.viewControllers;
    if ([viewControllers.lastObject isKindOfClass:[controller class]]) return;
    
    NSInteger kCount = [viewControllers count];
    NSInteger i = 0;
    for (i = kCount - 1; i >= 0; i--) {
        UIViewController *viewController = [viewControllers objectAtIndex:i];
        if ([viewController isKindOfClass:[controller class]]) {
            //在栈里找到了
            if (urlAction.singletonType == XYSingletonTypeReuse || urlAction.singletonType == XYSingletonTypeRenew) {
                NSRange belowRange = NSMakeRange(0, i);
                NSArray <UIViewController *>*belowArray = [viewControllers subarrayWithRange:belowRange];
                NSRange topRange = NSMakeRange(i + 1, kCount - i - 1);
                NSArray <UIViewController *>*topArray = [viewControllers subarrayWithRange:topRange];
                UIViewController *obj = [viewControllers objectAtIndex:i];
                NSMutableArray <UIViewController *>*stacks = [NSMutableArray arrayWithArray:belowArray];
                [stacks addObjectsFromArray:topArray];
                if (urlAction.singletonType == XYSingletonTypeReuse) {
                    //Reuse
                    [stacks addObject:obj];
                    if (urlAction.naviTransition != nil) {
                        [self.navigationContorller.view.layer addAnimation:urlAction.naviTransition.transition forKey:kCATransition];
                    } else {
                        CATransition *transition = [self defaultTransiton];
                        [self.navigationContorller.view.layer addAnimation:transition forKey:kCATransition];
                    }
                    [self.navigationContorller setViewControllers:stacks animated:NO];
                    
                } else {
                    //Renew
                    [self.navigationContorller setViewControllers:stacks animated:NO];
                    if (urlAction.naviTransition != nil) {
                        [self.navigationContorller pushViewController:controller withTransition:urlAction.naviTransition];
                    } else {
                        if ([controller respondsToSelector:@selector(handleWithURLAction:)]) {
                            [controller handleWithURLAction:urlAction];
                        }
                        CATransition *transition = [self defaultTransiton];
                        [self.navigationContorller.view.layer addAnimation:transition forKey:kCATransition];
                        [self.navigationContorller pushViewController:controller animated:NO];
                    }
                }
           
            } else {
                //Retop
                XYNaviAnimation animation = XYNaviAnimationNone;
                animation = urlAction.animation;
                [self.navigationContorller popToViewController:viewController withTransition:urlAction.naviTransition];
            }
            return;
        }
    }
    //在栈里没找到
    if (i < 0) {
        [self openViewController:controller withURLAction:urlAction];
    }
}

- (CATransition *)defaultTransiton
{
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionMoveIn;            //改变视图控制器出现的方式
    transition.subtype = kCATransitionFromTop;     //出现的位置
    transition.duration = 0.3;
    return transition;
}

@end
