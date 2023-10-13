## **Python 入门语法**

### **什么是变量?**

变量就是可以变化的量，量指的是事物的状态，比如人的年龄、性别，游戏角色的等级、金钱等等

- 变量的组成部分: 变量名+赋值符号+变量值

### **如何使用变量?**

先定义,后使用

```python
name = 'Jason' # 记下人的名字为'Jason'
sex = '男'    # 记下人的性别为男性
age = 18      # 记下人的年龄为18岁
salary = 30000.1  # 记下人的薪资为30000.1元
```

### **变量的命名规范?**

- 变量名只能是字母数字或者下划线的任意组合
- 变量名第一个字符不能是数字
- 关键字不能声明为变量名,例如:`['and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'exec', 'finally', 'for', 'from','global', 'if', 'import', 'in', 'is', 'lambda', 'not', 'or', 'pass', 'print', 'raise', 'return', 'try', 'while', 'with', 'yield']`


### **变量名的命名风格?**

1. 驼峰体: `ToNy = 20`
2. 纯小写+下划线 `dog_name  = zhangsan`


### **变量值的三大特性**


- id : 反应的是变量在内存中的唯一编号,内存地址不同 id 肯定不同

- type : 变量值的类型

- values : 变量值


### **基本数据类型**

在 python 中常用的数据类型包含以下几种(int 类型,float 浮点型,字符串类型,列表,字典,布尔值)

#### int 类型: 
- 用来记录年龄,年份,学生人数等相关状态

```
age = 18
class_id  = 176
```
#### float浮点型:
- 用来记录身高体重,薪资这些小数的状态

```python
weight=11.5
height=3434.4
```

#### 字符串类型:
- 用来记录人的名字,住址,描述性质状态

```python 
dog_name = 'tom'
dog_address = '朝阳'
dog_sex = '公'
```

- 用单引号,多引号,都可以定义字符串,本质上是没有区别的

```
msg = 'my name is lili'
```

- 使用:

```
name='zhangsan'
age='18'
print(name + age) # 相加就是简单的字符串拼接
zhangsan18


print(name * 5)
zhangsanzhangsanzhangsanzhangsanzhangsan # 相乘就相当于字符串*5
```

#### 列表:
用于记录同一种属性的多个值,例如一个班级的所有学生名字

定义:

```python
class_name = ['zhangsan','lisi','wangwu']
```

使用:
```python
$ python3            
Python 3.11.5 (main, Aug 24 2023, 15:09:45) [Clang 14.0.3 (clang-1403.0.22.14.1)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> class_name = ['zhangsan','lisi','wangwu'] # 通过索引进行取值
>>> class_name[0]
'zhangsan'
>>> class_name[1]
'lisi'
>>> class_name[2]
'wangwu'


>>> class_info = [['zhangsan',12],['lisi',],['wangwu',23]] # 列表嵌套
>>> class_info[1][0]
'lisi'
>>> class_info[2][1]
23
```

#### 字典 dict

作用:
我们有一些场景,我们需要一个变量来记录多个值,但是多个值的属性是不同的

```
dic_info = {'name':'lixie','age':20,weight:3434.3}
>>> dic_info['age']
20
>>> dic_info['name']
'lixie'
```

#### 布尔值 bool

```
True
False
```