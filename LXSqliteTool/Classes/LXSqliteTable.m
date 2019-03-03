//
//  LXSqliteTable.m
//  数据库封装
//
//  Created by wenglx on 2017/4/6.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import "LXSqliteTable.h"
#import "LXSqliteTool.h"

@implementation LXSqliteTable
/**
 *  根据UID和模型类型 [排序数据库列名]
 */
+ (NSArray *)lx_sqliteTableStoredColumnNames:(Class)cls UID:(NSString *)uid
{
    NSString *sql = [NSString stringWithFormat:@"select sql from sqlite_master where name = '%@';",NSStringFromClass(cls)];
    NSString *createdTableSql = [LXSqliteTool lx_executeQueryWithSQL:sql UID:uid].firstObject[@"sql"];
    NSString *tempString = [createdTableSql componentsSeparatedByString:@"("][1];
    NSArray *columnNameTypes = [tempString componentsSeparatedByString:@","];
    NSMutableArray *columnNames = [NSMutableArray array];
    for (NSString *columnNameType in columnNameTypes) {
        if ([columnNameType containsString:@"primary"]) {
            continue;
        }
        [columnNames addObject:[columnNameType componentsSeparatedByString:@" "].firstObject];
    }
    return [columnNames sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
}

@end
