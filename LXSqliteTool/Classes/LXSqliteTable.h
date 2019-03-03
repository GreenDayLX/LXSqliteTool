//
//  LXSqliteTable.h
//  数据库封装
//
//  Created by wenglx on 2017/4/6.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXSqliteTable : NSObject
/**
 *  根据UID和模型类型 [排序数据库列名]
 */
+ (NSArray *)lx_sqliteTableStoredColumnNames:(Class)cls UID:(NSString *)uid;

@end
