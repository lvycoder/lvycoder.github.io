
### **认识 Github:**

Github顾名思义是一个Git版本库的托管服务，是目前全球最大的软件仓库，拥有上百万的开发者用户，也是软件开发和寻找资源的最佳途径，Github不仅可以托管各种Git版本仓库，还拥有了更美观的Web界面，您的代码文件可以被任何人克隆，使得开发者为开源项贡献代码变得更加容易，当然也可以付费购买私有库，这样高性价比的私有库真的是帮助到了很多团队和企业。

![](https://pic1.imgdb.cn/item/6333f08a16f2c2beb101796d.png)






### **一、注册Github帐号**

1.1. 进入github的官网: https://github.com/


![](https://pic1.imgdb.cn/item/63342d7b16f2c2beb141f07e.png)

1.2. 点击注册账号
![](https://pic1.imgdb.cn/item/63342e0216f2c2beb1426bdc.png)

!!! warning "温馨提示"
    - 用户昵称，建议用有特色自己的，而且不要太长，要好记，以后对创建仓库有很大的帮助。
    - 电子邮箱地址，填写你常用的，不要乱填，一会是要发激活链接到你邮箱的。
    - 用户密码，确保至少15个字符或至少8个字符（ 包括数字 和小写字母）
    - 输入完会有一个人机验证，你只需把图片矫正即可。



![](https://pic1.imgdb.cn/item/63342faa16f2c2beb14409e4.png)

1.3. 选择个人版

![](https://pic1.imgdb.cn/item/633430f716f2c2beb1457fb1.jpg)

1.4. 选择兴趣

![](https://pic1.imgdb.cn/item/6334302d16f2c2beb1449890.png)


1.5.验证邮箱

![](https://pic1.imgdb.cn/item/633430a116f2c2beb145215a.png)

到这里基本就完成了对github帐号的注册。


### **二、创建仓库**

2.1. 新建一个公共仓库
![](https://pic1.imgdb.cn/item/633431fe16f2c2beb146951d.png)

2.2. 初始化仓库
![](https://pic1.imgdb.cn/item/6334322716f2c2beb146bb1c.png)



### **三、提交代码**


!!! tip "Github 提交 pr"
    - 代码commit规约: https://www.conventionalcommits.org/zh-hans/v1.0.0/





```shell
git checkout -b lixie   //切换到lixie分支
git add .
git status   // 查看暂存区提交的内容
git commit -m "feat(ssh): add lixie for sjtu" 
git branch
git remote
origin
git branch //查看分支
git push origin lixie  //将代码上传远程lixie分支

git rebase origin/master
git push origin lixie
git push origin lixie  -f 强制提交到lixie分区
```



### **四、配置公钥**

4.1. 生成密钥对
```
root@a100-1:/home/lixie# ssh-keygen   //一路回车
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:a92LUGI9FIkRl7wUlOVKqh3Xtsigo2XkG8iau0JKHUE root@a100-1
The key's randomart image is:
+---[RSA 3072]----+
|  .E    o*=*.    |
|   .    ..*o     |
|    .    .o..    |
|   .     =.o     |
|  . . . S * o    |
| o o + = X = .   |
|+   o O = + o    |
|o  o + = . . .   |
| .=o. .   . .    |
+----[SHA256]-----+

// 家目录下就会生成几个文件
root@a100-1:~# ls .ssh/
authorized_keys  id_rsa  id_rsa.pub
```
4.2. 将公钥上传到github
![](https://pic1.imgdb.cn/item/6335458216f2c2beb1320354.jpg)

需要给公钥起一个名称，复制自己刚刚创建的公钥
![](https://pic1.imgdb.cn/item/633545ea16f2c2beb132741b.jpg)

上传完成之后，就不需要提交的时候再输入密码验证了。windows也类似可以自行百度。


!!! note "windows 使用git"
    - 网站地址: https://git-for-windows.github.io
    - 下载地址: https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe 