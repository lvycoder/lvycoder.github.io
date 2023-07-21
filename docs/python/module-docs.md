一. python文件的两种用途？
- 当作程序运行
- 当作模块倒入


```python
print(__name__) # 没有导入模块__name__ == '__main__'. 导入之后等于模块名称

if __name__ == '__main__':
    get()
    change()
else:
    pass
```
