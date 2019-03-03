//
//  LXSqliteTool.m
//  数据库封装
//
//  Created by wenglx on 2017/4/5.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import "LXSqliteTool.h"
#import "sqlite3.h"

/** 数据库路径 */
#define kCaches NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject

@implementation LXSqliteTool
/**
 *  数据库
 */
static sqlite3 *ppDb;

/**
 *  执行[增、删、改]语句
 */
+ (BOOL)lx_executeUpdateWithSQL:(NSString *)sql UID:(NSString *)uid
{
    [self lx_openDBWithUID:uid];
    char *errmsg;
    BOOL result = sqlite3_exec(ppDb, sql.UTF8String, NULL, NULL, &errmsg) == SQLITE_OK;
    if (!result && errmsg) {
        NSLog(@"数据库执行操作失败 - 错误信息：%s",errmsg);
    }
    [self lx_closeDB];
    return result;
}

/**
 *  执行多条[增、删、改]语句
 */
+ (BOOL)lx_executeUpdateWithSqls:(NSArray *)sqls UID:(NSString *)uid
{
    [self lx_openDBWithUID:uid];
    sqlite3_exec(ppDb, @"begin transaction;".UTF8String, NULL, NULL, NULL);
    char *errmsg;
    for (NSString *sql in sqls) {
        BOOL result = sqlite3_exec(ppDb, sql.UTF8String, NULL, NULL, &errmsg) == SQLITE_OK;
        if (!result || errmsg) {
            sqlite3_exec(ppDb, @"rollback transaction;".UTF8String, NULL, NULL, NULL);
            return NO;
        }
    }
    sqlite3_exec(ppDb, @"commite transaction;".UTF8String, NULL, NULL, NULL);
    [self lx_closeDB];
    return YES;
}

/**
 *  执行[查]语句
 */
+ (NSArray *)lx_executeQueryWithSQL:(NSString *)sql UID:(NSString *)uid
{
    [self lx_openDBWithUID:uid];
    sqlite3_stmt *ppStmt;
    BOOL result = sqlite3_prepare_v2(ppDb, sql.UTF8String, -1, &ppStmt, NULL) == SQLITE_OK;
    if (!result) {
        NSLog(@"数据库预处理语句创建失败");
        sqlite3_finalize(ppStmt);
        [self lx_closeDB];
        return nil;
    }
    NSMutableArray *rowDicts = [NSMutableArray array];
    while (sqlite3_step(ppStmt) == SQLITE_ROW) {
        int columnCount = sqlite3_column_count(ppStmt);
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionary];
        [rowDicts addObject:rowDict];
        for (int i = 0; i < columnCount; i++) {
            NSString *columnKey = [NSString stringWithUTF8String:sqlite3_column_name(ppStmt, i)];
            int columnType = sqlite3_column_type(ppStmt, i);
            id columnValue;
            switch (columnType) {
                case SQLITE_INTEGER: {
                    columnValue = @(sqlite3_column_int(ppStmt, i));
                    break;
                }
                case SQLITE_FLOAT: {
                    columnValue = @(sqlite3_column_double(ppStmt, i));
                    break;
                }
                case SQLITE_BLOB: {
                    columnValue = CFBridgingRelease(sqlite3_column_blob(ppStmt, i));
                    break;
                }
                case SQLITE_NULL: {
                    columnValue = @"";
                    break;
                }
                case SQLITE3_TEXT: {
                    columnValue = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(ppStmt, i)];
                    break;
                }
                default:
                    break;
            }
            [rowDict setValue:columnValue forKeyPath:columnKey];
        }
    }
    sqlite3_finalize(ppStmt);
    [self lx_closeDB];
    return rowDicts;
}

/**
 *  根据UID创建并开打数据库
 */
+ (BOOL)lx_openDBWithUID:(NSString *)uid
{
    NSString *dbPath = [kCaches stringByAppendingPathComponent:@"common.sqlite"];
    if (uid.length > 0) {
        dbPath = [kCaches stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",uid]];
    }
    BOOL result = sqlite3_open(dbPath.UTF8String, &ppDb) == SQLITE_OK;
    if (!result) {
        NSLog(@"数据库创建并打开失败");
    }
    return result;
}

/**
 *  关闭数据库
 */
+ (void)lx_closeDB
{
    sqlite3_close(ppDb);
}


@end
