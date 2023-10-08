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