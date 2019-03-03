//
//  LXSqliteModelProtocol.h
//  数据库封装
//
//  Created by wenglx on 2017/4/6.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LXSqliteModelProtocol <NSObject>

@required
+ (NSString *)lx_primaryKey;

@optional
+ (NSArray *)lx_ignoreColumnNames;
+ (NSDictionary *)lx_renameNewNameToOldName;

@end
