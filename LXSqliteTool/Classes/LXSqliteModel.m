//
//  LXSqliteModel.m
//  数据库封装
//
//  Created by wenglx on 2017/4/5.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import "LXSqliteModel.h"
#import <objc/message.h>
#import "LXSqliteModelProtocol.h"

@implementation LXSqliteModel
/**
 *  根据模型类型 [创建表名]
 */
+ (NSString *)lx_tableNameWithModelClass:(Class)cls
{
    return NSStringFromClass(cls);
}

/**
 *  根据模型类型 [创建临时表名]
 */
+ (NSString *)lx_tempTableNameWithModelClass:(Class)cls
{
    return [NSStringFromClass(cls) stringByAppendingString:@"_temp"];
}

/**
 *  根据模型类型 [排序成员变量名]
 */
+ (NSArray *)lx_modelIvarSortedNamesWithModelClass:(Class)cls
{
    NSArray *ivarNames = [self lx_modelIvarNameAndIvarTypeWithModelClass:cls].allKeys;
    return [ivarNames sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
}

/**
 *  根据模型类型 [获取模型成员变量和类型]
 */
+ (NSDictionary *)lx_modelIvarNameAndIvarTypeWithModelClass:(Class)cls
{
    unsigned int outCount;
    Ivar *ivarList = class_copyIvarList(cls, &outCount);
    NSMutableDictionary *ivarDict = [NSMutableDictionary dictionary];
    for (int i = 0; i <outCount; i++) {
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivarList[i])];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        NSArray *ignoreNames;
        if ([cls respondsToSelector:@selector(lx_ignoreColumnNames)]) {
            ignoreNames = [cls lx_ignoreColumnNames];
        }
        if ([ignoreNames containsObject:ivarName]) continue;
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivarList[i])];
        if ([ivarType hasPrefix:@"@\""]) {
            ivarType = [ivarType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        }
        [ivarDict setValue:ivarType forKeyPath:ivarName];
    }
    return ivarDict;
}

/**
 *  根据模型类型 [获取模型成员变量和成员变量在数据库中的类型]
 */
+ (NSDictionary *)lx_modelIvarNameAndSqliteTypeWithModelClass:(Class)cls
{
    NSDictionary *nameTypeDict = [self lx_modelIvarNameAndIvarTypeWithModelClass:cls];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [nameTypeDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [result setValue:[self lx_modelIvarTypeToSqliteType][obj] forKeyPath:key];
    }];
    return result;
}

/**
 *  根据模型类型 [获取模型成员变量和成员变量在数据库中的类型] 拼接的字符串
 */
+ (NSString *)lx_modelIvarNameAndSqliteTypeStringWithModelClass:(Class)cls
{
    NSDictionary *reslutDict = [self lx_modelIvarNameAndSqliteTypeWithModelClass:cls];
    NSMutableArray *results = [NSMutableArray array];
    [reslutDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *tempStr = [NSString stringWithFormat:@"%@ %@",key, obj];
        [results addObject:tempStr];
    }];
    return [results componentsJoinedByString:@","];
}

/**
 *  映射 - [模型成员变量类型] : [成员变量在数据库中类型]
 */
+ (NSDictionary *)lx_modelIvarTypeToSqliteType
{
    return @{
             @"d"                   : @"real",     // double
             @"f"                   : @"real",     // float
             
             @"i"                   : @"integer",  // int
             @"q"                   : @"integer",  // long
             @"Q"                   : @"integer",  // long long
             @"B"                   : @"integer",  // bool
             
             @"NSData"              : @"blob",
             @"NSDictionary"        : @"text",
             @"NSMutableDictionary" : @"text",
             @"NSArray"             : @"text",
             @"NSMutableArray"      : @"text",
             
             @"NSString"            : @"text"
             };
}


@end
