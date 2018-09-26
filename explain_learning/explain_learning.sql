-- 建表user_info语句
CREATE TABLE `user_info` (
  `id`   BIGINT(20)  NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `age`  INT(11)              DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name_index` (`name`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8

-- 初始化 user_info 数据
INSERT INTO user_info (name, age) VALUES ('xys', 20);
INSERT INTO user_info (name, age) VALUES ('a', 21);
INSERT INTO user_info (name, age) VALUES ('b', 23);
INSERT INTO user_info (name, age) VALUES ('c', 50);
INSERT INTO user_info (name, age) VALUES ('d', 15);
INSERT INTO user_info (name, age) VALUES ('e', 20);
INSERT INTO user_info (name, age) VALUES ('f', 21);
INSERT INTO user_info (name, age) VALUES ('g', 23);
INSERT INTO user_info (name, age) VALUES ('h', 50);
INSERT INTO user_info (name, age) VALUES ('i', 15);


-- 建表order_info语句
CREATE TABLE `order_info` (
  `id`           BIGINT(20)  NOT NULL AUTO_INCREMENT,
  `user_id`      BIGINT(20)           DEFAULT NULL,
  `product_name` VARCHAR(50) NOT NULL DEFAULT '',
  `productor`    VARCHAR(30)          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_product_detail_index` (`user_id`, `product_name`, `productor`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8

-- 初始化order_info数据
INSERT INTO order_info (user_id, product_name, productor) VALUES (1, 'p1', 'WHH');
INSERT INTO order_info (user_id, product_name, productor) VALUES (1, 'p2', 'WL');
INSERT INTO order_info (user_id, product_name, productor) VALUES (1, 'p1', 'DX');
INSERT INTO order_info (user_id, product_name, productor) VALUES (2, 'p1', 'WHH');
INSERT INTO order_info (user_id, product_name, productor) VALUES (2, 'p5', 'WL');
INSERT INTO order_info (user_id, product_name, productor) VALUES (3, 'p3', 'MA');
INSERT INTO order_info (user_id, product_name, productor) VALUES (4, 'p1', 'WHH');
INSERT INTO order_info (user_id, product_name, productor) VALUES (6, 'p1', 'WHH');
INSERT INTO order_info (user_id, product_name, productor) VALUES (9, 'p8', 'TE');



-- explain 学习                       --

-- 这里的select_type是SIMPLE 即没有子查询和UOION查询
-- 这个返回结果是走主键index的，所以type是const的 （const指走主键或唯一索引的数据,且最多只返回一条数据）
explain select * from user_info where id = 2;



--  这里的explian 结果有三行，select_type PRIMARY（最外面的查询）UNION(UNION第二个或者)  UNION RESULT(整个语句执行explain的结果)
explain
select * from user_info where id in (1,2,3)
union
select * from user_info where id in (3,4,5);


-- 这个explain结果有两行 第一行是order_info表的查询，这个走的是索引，type是index（表示走了全索引扫描），而第二个结果表示user_info表的查询分析，
-- user_info中的id值对应前表的中的结果，都只能匹配到一行结果，并且查询的条件是 = 效率比较高 type是eq_ref
explain
select * from user_info,order_info where user_info.id = order_info.user_id;


-- 这个explain结果有两行 第一行是user_info的查询，因为走的是主键索引，所以type是const
-- 第二个结果是order_info的查询，type是ref 走的是非主键非唯一的索引。满足最左前缀
explain
select * from user_info,order_info where user_info.id = order_info.user_id and user_info.`id` = 5;


-- 这个对id进行了范围查询，type是range
explain
select * from user_info where id between 2 and 8;


-- 这个查询会走建立好的索引，即走全索引扫描，type是index，这个时候extra是using index
explain
select name from user_info;


-- 全表扫描的type = all，因为没给age建立索引 走的全表扫描
explain
select age from user_info where age = 20;


-- order_info中有联合索引  ('user_id','product_name','productor')
-- 这时因为user_id使用了范围查询，按照索引最左前缀匹配原则，当遇到范围查询时，就停止索引的匹配，这个时候只会去用user_id这个索引，所以这个key_len为9（bigint占8个字节，可以为NULL占一个字节，如果改成NOT_NULL的，这个时候key_len为8）
explain
select * from order_info where user_id < 3 and product_name ='p1' and productor = 'WHH';


-- 这个走了两个索引user_id 和 product_name 这个时候key_len是160。编码是utf8 varchar和char的key_len计算规则是 3n + 2 （utfmb4是 4n + 2）
-- 这个key_len = user_id (8) + product_name(3 * 50 + 2) = 160
explain
select * from order_info where user_id = 1 and product_name = 'p1';


-- 这个查询的执行计划 type是index，表示全索引扫描，指扫描所有的数据。而根据product_name去分组不能走索引（因为索引是(user_id,product_name,productor) ），这里的extra会展示 using filesort，而且key_len也是要计算联合索引中的三个值 ；
-- 而如果order by的条件是user_id，product_name 这个时候extra是using index，不会有using filesort
explain
select * from order_info order by product_name;

explain
select * from order_info order by user_id,product_name;
