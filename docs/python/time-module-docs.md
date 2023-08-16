# 常用模块：time，random，os模块

'''
import time

# 时间分为三种格式
# 1. 时间戳：从1970年到现在经历过的秒速
print(time.time()) # 用于时间间隔的计算

# 2. 按照某种格式显示时间：2020-03-30 11:11:11

print(time.strftime('%Y-%m-%d %H:%M:%S %p')) # 用于展示时间
print(time.strftime('%Y-%m-%d %X'))

# 3. 结构化时间
res=time.localtime() # 用于单独获取时间的某一部分
print(res)
print(res.tm_year)
print(res.tm_yday)
'''

# 二. datetime
'''
import datetime
print(datetime.datetime.now() + datetime.timedelta(days=1)) # 一天之后的时间
print(datetime.datetime.now() + datetime.timedelta(weeks=1)) # 一周之后的时间
'''








