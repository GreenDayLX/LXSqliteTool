//
//  LXSqliteModelTool.m
//  数据库封装
//
//  Created by wenglx on 2017/4/5.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import "LXSqliteModelTool.h"
#import "LXSqliteTool.h"
#import "LXSqliteModel.h"
#import "LXSqliteModelProtocol.h"
#import "LXSqliteTable.h"

@implementation LXSqliteModelTool

#pragma mark - 保存或更新相关
/**
 *  根据UID和模型类型 [保存或更新模型到数据库]
 */
+ (BOOL)lx_saveOrUpdateToSqliteWithModel:(id)model UID:(NSString *)uid
{
    Class cls = [model class];
    if (![self lx_isTableExistsWithModelClass:cls UID:uid]) {
        BOOL result = [self lx_createdTableWithModelClass:cls UID:uid];
        if (!result) return NO;
    }
    if (![self lx_isTableRequiredUpdateWithModelClass:cls UID:uid]) {
        BOOL result = [self lx_updateTableWithModelClass:cls UID:uid];
        if (!result) return NO;
    }
    // 判断需要存储的记录是否存在语句: select * from 表格名 where 主键 = '给定的主键值';
    if (![cls respondsToSelector:@selector(lx_primaryKey)]) {
        NSLog(@"如果想使用这个框架操作模型存储到数据库，模型必须遵守 <LXSqliteModelProtocol> 协议并实现 [+ (NSString *)lx_primaryKey;] 设置主键方法");
        return NO;
    }
    NSString *primaryKey = [cls lx_primaryKey];
    NSString *primaryKeyValue = [model valueForKeyPath:primaryKey];
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *rowExistsSql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@';",tableName, primaryKey, primaryKeyValue];
    NSArray *rows = [LXSqliteTool lx_executeQueryWithSQL:rowExistsSql UID:uid];
    // 所有字段和字段值
    NSArray *columnNames = [LXSqliteModel lx_modelIvarNameAndIvarTypeWithModelClass:cls].allKeys;
    id columnValue;
    NSData *columnValueData;
    NSMutableArray *columnValues = [NSMutableArray array];
    for (NSString *columnName in columnNames) {
        columnValue = [model valueForKeyPath:columnName];
        if (columnValue == nil) {
            columnValue = @"";
        }
        if ([columnValue isKindOfClass:[NSArray class]] || [columnValue isKindOfClass:[NSDictionary class]]) {
            columnValueData = [NSJSONSerialization dataWithJSONObject:columnValue options:NSJSONWritingPrettyPrinted error:nil];
            columnValue = [[NSString alloc] initWithData:columnValueData encoding:NSUTF8StringEncoding];
        }
        [columnValues addObject:columnValue];
    }
    // 判断是更新还是插入
    if (rows.count > 0) {
        // 根据主键更新表格语句: update 表格名 set 字段1='字段1值',字段2='字段2值'...where 主键 = '主键值';
        NSInteger columnCount = columnNames.count;
        NSString *columnName;
        NSString *setSql;
        NSMutableArray *setSqls = [NSMutableArray array];
        for (int i = 0; i < columnCount; i++) {
            columnName = columnNames[i];
            columnValue = columnValues[i];
            setSql = [NSString stringWithFormat:@"%@='%@'",columnName, columnValue];
            [setSqls addObject:setSql];
        }
        setSql = [setSqls componentsJoinedByString:@","];
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ where %@ = '%@';",tableName, setSql, primaryKey, primaryKeyValue];
        return [LXSqliteTool lx_executeUpdateWithSQL:updateSql UID:uid];
    }
    // 根据主键更新表格语句: insert into 表格名(字段1,字段2...) values ('字段1值','字段2值'...);
    NSString *columnNameStr = [columnNames componentsJoinedByString:@","];
    NSString *columnValueStr = [columnValues componentsJoinedByString:@"\',\'"];
    NSString *insertSql = [NSString stringWithFormat:@"insert into %@(%@) values ('%@');",tableName, columnNameStr, columnValueStr];
    return [LXSqliteTool lx_executeUpdateWithSQL:insertSql UID:uid];
}

/**
 *  根据UID、模型数组并设置是否有主键 [保存或更新模型到数据库]
 *  'hasPK'参数：是否有主键，含义是服务器返回的数据中是否有可以当做主键的key，
 *              如果有就是YES，如果没有，需要写一个'pmKey'的属性设置为主键并设置为NO。
 */
+ (BOOL)lx_saveOrUpdateToSqliteWithModels:(NSArray *)models hasPrimaryKey:(BOOL)hasPK UID:(NSString *)uid
{
    NSInteger modelCount = models.count;
    if (modelCount <= 0) return NO;
    BOOL isHas = hasPK;
    id model;
    for (int i = 0; i < modelCount; i++) {
        model = models[i];
        if (!isHas) {
            [model setValue:@(i) forKeyPath:@"pmKey"];
        }
        [self lx_saveOrUpdateToSqliteWithModel:models[i] UID:uid];
    }
    return YES;
}

/**
 *  根据UID、模型类型和所需要的更新的key = 'value' [更新模型到数据库]
 */
+ (BOOL)lx_updateToSqliteWithModelClass:(Class)cls keyRelationValueStr:(NSString *)keyRelationValueStr UID:(NSString *)uid
{
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    // 判断需要存储的记录是否存在语句: select * from 表格名 where 主键 = '给定的主键值';
    if (![cls respondsToSelector:@selector(lx_primaryKey)]) {
        NSLog(@"如果想使用这个框架操作模型存储到数据库，模型必须遵守 <LXSqliteModelProtocol> 协议并实现 [+ (NSString *)lx_primaryKey;] 设置主键方法");
        return NO;
    }
    NSString *primaryKey = [cls lx_primaryKey];
    NSString *updateSql = [NSString stringWithFormat:@"update %@",tableName];
    if (keyRelationValueStr.length > 0) {
        updateSql = [updateSql stringByAppendingFormat:@" set %@ where %@ = '%@';",keyRelationValueStr, primaryKey, uid];
    } else {
        return NO;
    }
    return [LXSqliteTool lx_executeUpdateWithSQL:updateSql UID:uid];
}

/**
 *  根据UID和模型类型 [判断表格是否存在]
 */
+ (BOOL)lx_isTableExistsWithModelClass:(Class)cls UID:(NSString *)uid
{
    // 判断表格是否存在语句: select * from sqlite_master where type = 'table' and name = '表格名';
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *isExistsSql = [NSString stringWithFormat:@"select * from sqlite_master where type = 'table' and name = '%@';",tableName];
    return [LXSqliteTool lx_executeQueryWithSQL:isExistsSql UID:uid].count >= 1;
}

/**
 *  根据UID和模型类型 [创建表格]
 */
+ (BOOL)lx_createdTableWithModelClass:(Class)cls UID:(NSString *)uid
{
    // 创建表格语句: created table if not exists 表格名(模型成员变量与成员变量在数据库中的类型,primary key(主键));
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *nameTypeStr = [LXSqliteModel lx_modelIvarNameAndSqliteTypeStringWithModelClass:cls];
    if (![cls respondsToSelector:@selector(lx_primaryKey)]) {
        NSLog(@"如果想使用这个框架操作模型存储到数据库，模型必须遵守 <LXSqliteModelProtocol> 协议并实现 [+ (NSString *)lx_primaryKey;] 设置主键方法");
        return NO;
    }
    NSString *primaryKey = [cls lx_primaryKey];
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@(%@,primary key(%@));",tableName, nameTypeStr, primaryKey];
    return [LXSqliteTool lx_executeUpdateWithSQL:sql UID:uid];
}

/**
 *  根据UID和模型类型 [判断表格是否需要更新]
 */
+ (BOOL)lx_isTableRequiredUpdateWithModelClass:(Class)cls UID:(NSString *)uid
{
    NSArray *modelIvarNames = [LXSqliteModel lx_modelIvarSortedNamesWithModelClass:cls];
    NSArray *tableColumnNames = [LXSqliteTable lx_sqliteTableStoredColumnNames:cls UID:uid];
    return ![modelIvarNames isEqualToArray:tableColumnNames];
}

/**
 *  根据UID和模型类型 [更新表格]
 */
+ (BOOL)lx_updateTableWithModelClass:(Class)cls UID:(NSString *)uid
{
    NSMutableArray *sqls = [NSMutableArray array];
    NSString *tempTableName = [LXSqliteModel lx_tempTableNameWithModelClass:cls];
    NSString *oldTableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *nameTypeStr = [LXSqliteModel lx_modelIvarNameAndSqliteTypeStringWithModelClass:cls];
    if (![cls respondsToSelector:@selector(lx_primaryKey)]) {
        NSLog(@"如果想使用这个框架操作模型存储到数据库，模型必须遵守 <LXSqliteModelProtocol> 协议并实现 [+ (NSString *)lx_primaryKey;] 设置主键方法");
        return NO;
    }
    NSString *primaryKey = [cls lx_primaryKey];
    // created table if not exists 临时表格名(模型名称和类型,primary key(主键))
    NSString *createdSql = [NSString stringWithFormat:@"create table if not exists %@(%@,primary key(%@));",tempTableName, nameTypeStr, primaryKey];
    [sqls addObject:createdSql];
    // insert into 临时表格名(主键) select 主键 from 旧表格名
    NSString *insertSql = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@;",tempTableName, primaryKey, primaryKey, oldTableName];
    [sqls addObject:insertSql];
    // update 临时表格名 set 新的字段名 = (select 旧的字段名 from 旧表格名 where 旧表格名.主键 = 临时表格名.主键)
    NSArray *newColumnNames = [LXSqliteModel lx_modelIvarSortedNamesWithModelClass:cls];
    NSArray *oldColumnNames = [LXSqliteTable lx_sqliteTableStoredColumnNames:cls UID:uid];
    NSString *updateSql;
    NSString *oldName;
    NSDictionary *renameDict;
    if ([cls respondsToSelector:@selector(lx_renameNewNameToOldName)]) {
        renameDict = [cls lx_renameNewNameToOldName];
    }
    for (NSString *newColumnName in newColumnNames) {
        oldName = [renameDict valueForKeyPath:newColumnName];
        if (oldName.length == 0 && ![oldColumnNames containsObject:oldName]) {
            oldName = newColumnName;
        }
        if ((![oldColumnNames containsObject:newColumnName] && ![oldColumnNames containsObject:oldName]) || [oldName isEqualToString:primaryKey]) continue;
        updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@);",tempTableName, newColumnName, oldName, oldTableName, oldTableName, primaryKey, tempTableName, primaryKey];
        [sqls addObject:updateSql];
    }
    // drop table if exists 旧表格名
    NSString *dropSql = [NSString stringWithFormat:@"drop table if exists %@;",oldTableName];
    [sqls addObject:dropSql];
    // alter table 临时表格名 rename to 旧表格名
    NSString *alterSql = [NSString stringWithFormat:@"alter table %@ rename to %@;",tempTableName, oldTableName];
    [sqls addObject:alterSql];
    
    return [LXSqliteTool lx_executeUpdateWithSqls:sqls UID:uid];
}

#pragma mark - 删除相关
/**
 *  根据UID和模型类型 [删除数据库中的某个表格]
 */
+ (BOOL)lx_dropTableFromSqliteWithModelClass:(Class)cls UID:(NSString *)uid
{
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *dropSql = [NSString stringWithFormat:@"drop table if exists %@;",tableName];
    return [LXSqliteTool lx_executeUpdateWithSQL:dropSql UID:uid];
}

/**
 *  根据UID和模型类型 [删除数据库中的所有表格]
 */
+ (BOOL)lx_dropTablesFromSqliteWithModels:(NSArray *)models UID:(NSString *)uid
{
    NSInteger modelCount = models.count;
    if (modelCount <= 0) return NO;
    for (int i = 0; i < modelCount; i++) {
        [self lx_dropTableFromSqliteWithModelClass:models[i] UID:uid];
    }
    return YES;
}

/**
 *  根据UID和模型 [删除某个表格的某个模型]
 */
+ (BOOL)lx_deleteModelWith:(id)model UID:(NSString *)uid
{
    // 根据主键删除某个表格的某个模型语句: delete from 表格名 where 主键 = '主键值';
    Class cls = [model class];
    if (![cls respondsToSelector:@selector(lx_primaryKey)]) {
        NSLog(@"如果想使用这个框架操作模型存储到数据库，模型必须遵守 <LXSqliteModelProtocol> 协议并实现 [+ (NSString *)lx_primaryKey;] 设置主键方法");
        return NO;
    }
    NSString *primaryKey = [cls lx_primaryKey];
    id primaryKeyValue = [model valueForKeyPath:primaryKey];
    return [self lx_deleteModelsWithModelClass:cls key:primaryKey relation:RelationTypeEqual value:primaryKeyValue UID:uid];
}

/**
 *  根据UID和模型类型 [删除某个表格数据]
 */
+ (BOOL)lx_deleteAllModelsWithModelClass:(Class)cls UID:(NSString *)uid
{
    // 删除某个表格语句: delete from 表格名;
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *deleteAllSql = [NSString stringWithFormat:@"delete from %@;",tableName];
    return [LXSqliteTool lx_executeUpdateWithSQL:deleteAllSql UID:uid];
}

/**
 *  根据UID、模型类型、一个或多个条件 [删除某个表格的某个或某些模型数据]
 */
+ (BOOL)lx_deleteModelsWithModelClass:(Class)cls keyRelationValueStr:(NSString *)keyRelationValueStr UID:(NSString *)uid
{
    // 删除某个表格的某个或某些模型数据语句: delete from 表格名 where x = 'y'...
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@",tableName];
    if (keyRelationValueStr.length > 0) {
        deleteSql = [deleteSql stringByAppendingFormat:@" where %@;",keyRelationValueStr];
    } else {
        deleteSql = [deleteSql stringByAppendingString:@";"];
    }
    return [LXSqliteTool lx_executeUpdateWithSQL:deleteSql UID:uid];
}

/**
 *  根据UID、模型类型、一个条件 [删除某个表格的某个或某些模型数据]
 */
+ (BOOL)lx_deleteModelsWithModelClass:(Class)cls key:(NSString *)key relation:(LXSqliteModelToolRelationType)relation value:(NSString *)value UID:(NSString *)uid
{
    // 删除某个表格的某个或某些模型数据语句: delete from 表格名 where x =... 'y'
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *relationStr = [self lx_relationTypeToRelationString][@(relation)];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ %@ '%@';",tableName, key, relationStr, value];
    return [LXSqliteTool lx_executeUpdateWithSQL:deleteSql UID:uid];
}

/**
 *  映射 - [条件类型] : [条件字符]
 */
+ (NSDictionary *)lx_relationTypeToRelationString
{
    return @{
             @(RelationTypeGreater)      : @">",
             @(RelationTypeLess)         : @"<",
             @(RelationTypeEqual)        : @"=",
             @(RelationTypeGreaterEqual) : @">=",
             @(RelationTypeLessEqual)    : @"<=",
             @(RelationTypeNotEqual)     : @"!="
             };
}

/**
 *  映射 - sql [逻辑运算符]
 */
+ (NSDictionary *)lx_naoTypeSQLRelation
{
    return @{
             @(LXSqliteModelToolNAONot) : @"not",
             @(LXSqliteModelToolNAOAnd) : @"and",
             @(LXSqliteModelToolNAOOr)  : @"or"
             };
}

#pragma mark - 查询相关
/**
 *  根据UID和模型类型 [查询某个表格的模型数据]
 */
+ (NSMutableArray *)lx_queryAllModelsWithModelClass:(Class)cls UID:(NSString *)uid
{
    // 查询某个表格的模型数据语句: select * from 表格名;
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *querySql = [NSString stringWithFormat:@"select * from %@;",tableName];
    NSArray *results = [LXSqliteTool lx_executeQueryWithSQL:querySql UID:uid];
    if (results.count == 0) {
        NSLog(@"无查询结果");
        return nil;
    }
    return [self lx_handleResults:results toModelWithClass:cls];
}

/**
 *  根据UID、模型类型和需要查询的'key' [查询某个表格的模型数据]
 */
+ (NSArray *)lx_queryModelsValueWithModelClass:(Class)cls Key:(NSString *)key UID:(NSString *)uid
{
    // 查询某个表格的模型数据语句: select * from 表格名;
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *querySql = [NSString stringWithFormat:@"select %@ from %@;", key,tableName];
    NSArray *results = [LXSqliteTool lx_executeQueryWithSQL:querySql UID:uid];
    if (results.count == 0) {
        NSLog(@"无查询结果");
        return nil;
    }
    return results;
}

/**
 *  根据UID、模型类型和需要查询的'key' [查询某个表格的模型数据中'key'对应的具体值]
 */
+ (id)lx_queryModelValueWithModelClass:(Class)cls Key:(NSString *)key UID:(NSString *)uid
{
    NSArray *tempArray = [self lx_queryModelsValueWithModelClass:cls Key:key UID:uid];
    NSDictionary *tempDict = tempArray.firstObject;
    return tempDict[key];
}

/**
 *  根据UID、模型类型、一个或多个条件 [查询某个表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls keyRelationValueStr:(NSString *)keyRelationValueStr UID:(NSString *)uid
{
    // 查询某个表格的某个或某些模型数据语句: select * from 表格名 where x = 'y'...
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *querySql = [NSString stringWithFormat:@"select from %@",tableName];
    if (keyRelationValueStr.length > 0) {
        querySql = [querySql stringByAppendingFormat:@" where %@;",keyRelationValueStr];
    } else {
        querySql = [querySql stringByAppendingString:@";"];
    }
    NSArray *results = [LXSqliteTool lx_executeQueryWithSQL:querySql UID:uid];
    if (results.count == 0) {
        NSLog(@"无查询结果");
        return nil;
    }
    return [self lx_handleResults:results toModelWithClass:cls];
}

/**
 *  根据UID、模型类型、一个条件 [查询某个表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls key:(NSString *)key relation:(LXSqliteModelToolRelationType)relation value:(NSString *)value UID:(NSString *)uid
{
    // 查询某个表格的某个或某些模型数据语句: select * from 表格名 where x =... 'y'
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *relationStr = [self lx_relationTypeToRelationString][@(relation)];
    NSString *querySql = [NSString stringWithFormat:@"select from %@ where %@ %@ '%@';",tableName, key, relationStr, value];
    NSArray *results = [LXSqliteTool lx_executeQueryWithSQL:querySql UID:uid];
    if (results.count == 0) {
        NSLog(@"无查询结果");
        return nil;
    }
    return [self lx_handleResults:results toModelWithClass:cls];
}

/**
 *  根据UID、模型类型、多个条件 [查询某个表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls keys: (NSArray *)keys relations: (NSArray *)relations values: (NSArray *)values nao: (NSArray *)naos uid: (NSString *)uid
{
    NSMutableString *resultStr = [NSMutableString string];
    for (int i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSString *relationStr = [self lx_relationTypeToRelationString][relations[i]];
        id value = values[i];
        NSString *tempStr = [NSString stringWithFormat:@"%@ %@ '%@'", key, relationStr, value];
        [resultStr appendString:tempStr];
        if (i != keys.count - 1) {
            NSString *naoStr = [self lx_naoTypeSQLRelation][naos[i]];
            [resultStr appendString:[NSString stringWithFormat:@" %@ ", naoStr]];
        }
    }
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@", tableName, resultStr];
    NSArray *results = [LXSqliteTool lx_executeQueryWithSQL:sql UID:uid];
    return [self lx_handleResults:results toModelWithClass:cls];
}


/**
 *  根据UID、模型类型、sql语句 [查询某个或某些表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls querySql:(NSString *)querySql UID:(NSString *)uid
{
    NSArray *results = [LXSqliteTool lx_executeQueryWithSQL:querySql UID:uid];
    if (results.count == 0) {
        NSLog(@"无查询结果");
        return nil;
    }
    return [self lx_handleResults:results toModelWithClass:cls];
}

/**
 *  按照主键倒序查询
 */
+ (NSArray *)lx_queryModelsOrderByPrimaryKeyDescWithModelClass:(Class)cls UID:(NSString *)uid
{
    NSString *tableName = [LXSqliteModel lx_tableNameWithModelClass:cls];
    if (![cls respondsToSelector:@selector(lx_primaryKey)]) {
        NSLog(@"如果想使用这个框架操作模型存储到数据库，模型必须遵守 <LXSqliteModelProtocol> 协议并实现 [+ (NSString *)lx_primaryKey;] 设置主键方法");
        return nil;
    }
    NSString *primaryKey = [cls lx_primaryKey];
    NSString *querySql = [NSString stringWithFormat:@"select * from %@ order by %@ desc;",tableName, primaryKey];
    return [self lx_queryModelsWithModelClass:cls querySql:querySql UID:uid];
}

/**
 *  根据模型类型 [处理查询结果]
 */
+ (NSMutableArray *)lx_handleResults:(NSArray *)results toModelWithClass:(Class)cls
{
    NSMutableArray *models = [NSMutableArray array];
    __block NSData *valueData;
    for (NSDictionary *rowDict in results) {
        id model = [[cls alloc] init];
        [models addObject:model];
        [rowDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[NSNumber class]]) {
                // 防止崩溃 - 提前判断是否是整数类型，因为整数类型找不到'isEqualToString:'方法
            } else if ([value isEqualToString:@"NSArray"] || [value isEqualToString:@"NSDictionary"]) {
                valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
                value = [NSJSONSerialization JSONObjectWithData:valueData options:kNilOptions error:nil];
            } else if ([value isEqualToString:@"NSMutableArray"] || [value isEqualToString:@"NSMutableDictionary"]) {
                valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
                value = [NSJSONSerialization JSONObjectWithData:valueData options:NSJSONReadingMutableContainers error:nil];
            }
            [model setValue:value forKeyPath:key];
        }];
    }
    return models;
}

@end
