//
//  LXSqliteTool.h
//  数据库封装
//
//  Created by wenglx on 2017/4/5.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXSqliteTool : NSObject
/**
 *  执行[增、删、改]语句
 */
+ (BOOL)lx_executeUpdateWithSQL:(NSString *)sql UID:(NSString *)uid;

/**
 *  执行多条[增、删、改]语句
 */
+ (BOOL)lx_executeUpdateWithSqls:(NSArray *)sqls UID:(NSString *)uid;

/**
 *  执行[查]语句
 */
+ (NSArray *)lx_executeQueryWithSQL:(NSString *)sql UID:(NSString *)uid;


@end
