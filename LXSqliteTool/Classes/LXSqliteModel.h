//
//  LXSqliteModel.h
//  数据库封装
//
//  Created by wenglx on 2017/4/5.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXSqliteModel : NSObject
/**
 *  根据模型类型 [创建表名]
 */
+ (NSString *)lx_tableNameWithModelClass:(Class)cls;

/**
 *  根据模型类型 [创建临时表名]
 */
+ (NSString *)lx_tempTableNameWithModelClass:(Class)cls;

/**
 *  根据模型类型 [获取模型成员变量和类型]
 */
+ (NSDictionary *)lx_modelIvarNameAndIvarTypeWithModelClass:(Class)cls;

/**
 *  根据模型类型 [获取模型成员变量和成员变量在数据库中的类型]
 */
+ (NSDictionary *)lx_modelIvarNameAndSqliteTypeWithModelClass:(Class)cls;

/**
 *  根据模型类型 [获取模型成员变量和成员变量在数据库中的类型] 拼接的字符串
 */
+ (NSString *)lx_modelIvarNameAndSqliteTypeStringWithModelClass:(Class)cls;

/**
 *  根据模型类型 [排序成员变量名]
 */
+ (NSArray *)lx_modelIvarSortedNamesWithModelClass:(Class)cls;

@end
