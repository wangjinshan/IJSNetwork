//
//  IJSNetworkDemoUITests.m
//  IJSNetworkDemoUITests
//
//  Created by 山神 on 2018/5/10.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface IJSNetworkDemoUITests : XCTestCase

@end


@implementation IJSNetworkDemoUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testExample {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *webViewsQuery = app.webViews;
    XCUIElement *element = [webViewsQuery childrenMatchingType:XCUIElementTypeOther].element;
    [element swipeUp];
    [element swipeDown];
    [element swipeUp];
    [webViewsQuery /*@START_MENU_TOKEN@*/.buttons[@"\U83b7\U53d6\U7528\U6237\U4fe1\U606f"] /*[[".otherElements[@\"ShareSDK for JS Sample\"].buttons[@\"\\U83b7\\U53d6\\U7528\\U6237\\U4fe1\\U606f\"]",".buttons[@\"\\U83b7\\U53d6\\U7528\\U6237\\U4fe1\\U606f\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ swipeUp];
    [element swipeUp];
    [element swipeDown];
    [webViewsQuery /*@START_MENU_TOKEN@*/.buttons[@"\U5206\U4eab\U5185\U5bb9"] /*[[".otherElements[@\"ShareSDK for JS Sample\"].buttons[@\"\\U5206\\U4eab\\U5185\\U5bb9\"]",".buttons[@\"\\U5206\\U4eab\\U5185\\U5bb9\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    [app.navigationBars[@"Authorize"].buttons[@"Cancel"] tap];
    [element swipeDown];
    [element swipeDown];
    [[[[[app.statusBars childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:0] tap];

    XCUIElement *reloadButton = app.buttons[@"reload"];
    [reloadButton tap];
    [element swipeUp];

    XCUIElement *stoploadingButton = app.buttons[@"stopLoading"];
    [stoploadingButton tap];

    XCUIElement *gobackButton = app.buttons[@"goBack"];
    [gobackButton tap];
    [gobackButton tap];
    [gobackButton tap];
    [stoploadingButton tap];
    [reloadButton tap];
    [element tap];
    [element swipeUp];
    [stoploadingButton tap];
    [element tap];
    [webViewsQuery /*@START_MENU_TOKEN@*/.buttons[@"\U5206\U4eab\U6d4b\U8bd5"] /*[[".otherElements[@\"\\U5206\\U4eab\\U6d4b\\U8bd5\"].buttons[@\"\\U5206\\U4eab\\U6d4b\\U8bd5\"]",".buttons[@\"\\U5206\\U4eab\\U6d4b\\U8bd5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    [app.alerts[@"Sample.html"].buttons[@"OK"] tap];
    [[[/*@START_MENU_TOKEN@*/ [app.tables.cells containingType:XCUIElementTypeImage identifier:@"icon_500px"] /*[["app.tables","[",".cells containingType:XCUIElementTypeStaticText identifier:@\"500px\"]",".cells containingType:XCUIElementTypeImage identifier:@\"icon_500px\"]"],[[[-1,0,1]],[[1,3],[1,2]]],[0,0]]@END_MENU_TOKEN@*/ childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:1] tap];

    XCUIElement *noPhotosGetStartedByUploadingAPhotoTable = app.tables[@"No Photos, Get started by uploading a photo."];
    [noPhotosGetStartedByUploadingAPhotoTable tap];
    [noPhotosGetStartedByUploadingAPhotoTable tap];
    [app.navigationBars[@"500px"].buttons[@"Applications"] tap];
    [self checkDomain:@"http://www.mob.com"];
}

- (NSString *)checkDomain:(NSString *)strName {
    if ([strName hasPrefix:@"http://"] || [strName hasPrefix:@"https://"]) {
        return strName;
    } else {
        return [NSString stringWithFormat:@"%@/%@", @"http//www.baidu.com", strName];
    }
}


@end
