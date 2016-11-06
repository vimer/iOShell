//
//  Global.h
//  iOShell
//
//  Created by 疯哥 on 7/22/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#ifndef iOShell_Global_h
#define iOShell_Global_h

#define HWColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

//XcodeColor plugin
#define XCODE_COLORS_ESCAPE @"\033["
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

//#ifdef DEBUG
    #ifdef TIME
            #define log(frmt, ...) NSLog((XCODE_COLORS_ESCAPE @"fg80,146,202;FILE=\%s,FUNC=%s,LINE=%d:\033[; \033[fg246,237,238;" frmt @"\n\n" XCODE_COLORS_RESET),[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
            #define logRed(frmt, ...) NSLog((XCODE_COLORS_ESCAPE @"fg6,146,202;[FILE=\%s,FUNC=%s,LINE=%d: \033[fg243,76,64;" frmt @"\n\n" XCODE_COLORS_RESET),[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
    #else
            #define log(FORMAT, ...) fprintf(stderr,"\033[fg80,146,202;[FILE=\%s,FUNC=%s,LINE=%d]:\033[; \033[fg246,237,238;%s\033[;\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
            #define logRed(FORMAT, ...) fprintf(stderr,"\033[fg6,146,202;[FILE=\%s,FUNC=%s,LINE=%d]:\033[; \033[fg243,76,64;%s\033[;\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
            #define logYellow(FORMAT, ...) fprintf(stderr,"\033[fg6,146,202;[FILE=\%s,FUNC=%s,LINE=%d]:\033[; \033[fg215,206,129;%s\033[;\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
    #endif
//#else
//
//#endif

#define g_test 1
#define appWidth CGRectGetWidth([[UIScreen mainScreen] bounds])
#define appHight CGRectGetHeight([[UIScreen mainScreen] bounds])

//#define g_configUrl  @"http://xxxxx/test_mobileconfig2/test_config.xml"
#define g_configUrl  @"http://www.xxxx.com/mobileconfig/config.xml"
#define g_lastUpdateTime @"0" //最后更新时间

#endif
