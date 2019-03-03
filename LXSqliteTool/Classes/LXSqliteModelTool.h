//
//  LXSqliteModelTool.h
//  数据库封装
//
//  Created by wenglx on 2017/4/5.
//  Copyright © 2017年 wenglx. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LXSqliteModelToolRelationType) {
    RelationTypeGreater = 1,  // >
    RelationTypeLess,         // <
    RelationTypeEqual,        // =
    RelationTypeGreaterEqual, // >=
    RelationTypeLessEqual,    // <=
    RelationTypeNotEqual      // !=
};

typedef NS_ENUM(NSUInteger, LXSqliteModelToolNAO) {
    LXSqliteModelToolNAONot = 1, // not
    LXSqliteModelToolNAOAnd,     // and
    LXSqliteModelToolNAOOr       // or
};

@interface LXSqliteModelTool : NSObject

#pragma mark - 保存或更新相关
/**
 *  根据UID和模型 [保存或更新模型到数据库]
 */
+ (BOOL)lx_saveOrUpdateToSqliteWithModel:(id)model UID:(NSString *)uid;
/**
 *  根据UID、模型数组并设置是否有主键 [保存或更新模型到数据库]
 *  'hasPK'参数：是否有主键，含义是服务器返回的数据中是否有可以当做主键的key，
 *              如果有就是YES，如果没有，需要写一个'pmKey'的属性设置为主键并设置为NO。
 */
+ (BOOL)lx_saveOrUpdateToSqliteWithModels:(NSArray *)models hasPrimaryKey:(BOOL)hasPK UID:(NSString *)uid;
/**
 *  根据UID、模型类型和所需要的更新的key = 'value' [更新模型到数据库]
 */
+ (BOOL)lx_updateToSqliteWithModelClass:(Class)cls keyRelationValueStr:(NSString *)keyRelationValueStr UID:(NSString *)uid;

#pragma mark - 删除相关
/**
 *  根据UID和模型类型 [删除数据库中的某个表格]
 */
+ (BOOL)lx_dropTableFromSqliteWithModelClass:(Class)cls UID:(NSString *)uid;
/**
 *  根据UID和模型类型 [删除数据库中的所有表格]
 */
+ (BOOL)lx_dropTablesFromSqliteWithModels:(NSArray *)models UID:(NSString *)uid;
/**
 *  根据UID和模型 [删除某个表格的某个模型数据]
 */
+ (BOOL)lx_deleteModelWith:(id)model UID:(NSString *)uid;
/**
 *  根据UID和模型类型 [删除某个表格数据]
 */
+ (BOOL)lx_deleteAllModelsWithModelClass:(Class)cls UID:(NSString *)uid;
/**
 *  根据UID、模型类型、一个或多个条件 [删除某个表格的某个或某些模型数据]
 */
+ (BOOL)lx_deleteModelsWithModelClass:(Class)cls keyRelationValueStr:(NSString *)keyRelationValueStr UID:(NSString *)uid;
/**
 *  根据UID、模型类型、一个条件 [删除某个表格的某个或某些模型数据]
 */
+ (BOOL)lx_deleteModelsWithModelClass:(Class)cls key:(NSString *)key relation:(LXSqliteModelToolRelationType)relation value:(NSString *)value UID:(NSString *)uid;

#pragma mark - 查询相关
/**
 *  根据UID和模型类型 [查询某个表格的模型数据]
 */
+ (NSMutableArray *)lx_queryAllModelsWithModelClass:(Class)cls UID:(NSString *)uid;
/**
 *  根据UID、模型类型和需要查询的'key' [查询某个表格的模型数据]
 */
+ (NSArray *)lx_queryModelsValueWithModelClass:(Class)cls Key:(NSString *)key UID:(NSString *)uid;
/**
 *  根据UID、模型类型和需要查询的'key' [查询某个表格的模型数据中'key'对应的具体值]
 */
+ (id)lx_queryModelValueWithModelClass:(Class)cls Key:(NSString *)key UID:(NSString *)uid;
/**
 *  根据UID、模型类型、一个或多个条件 [查询某个表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls keyRelationValueStr:(NSString *)keyRelationValueStr UID:(NSString *)uid;
/**
 *  根据UID、模型类型、一个条件 [查询某个表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls key:(NSString *)key relation:(LXSqliteModelToolRelationType)relation value:(NSString *)value UID:(NSString *)uid;
/**
 *  根据UID、模型类型、多个条件 [查询某个表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls keys: (NSArray *)keys relations: (NSArray *)relations values: (NSArray *)values nao: (NSArray *)naos uid: (NSString *)uid;
/**
 *  根据UID、模型类型、sql语句 [查询某个或某些表格的某个或某些模型数据]
 */
+ (NSArray *)lx_queryModelsWithModelClass:(Class)cls querySql:(NSString *)querySql UID:(NSString *)uid;
/**
 *  按照主键倒序查询
 */
+ (NSMutableArray *)lx_queryModelsOrderByPrimaryKeyDescWithModelClass:(Class)cls UID:(NSString *)uid;

@end
