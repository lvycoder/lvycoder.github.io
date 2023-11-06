## **报错指南**

### **问题复现:**

当我们在 `git fetch` 或 `git rebase` 我们本地有一些文件没有提交，就会出现以下这种情况。
```
$ git checkout lixie2
error: 您对下列文件的本地修改将被检出操作覆盖：
	ansible/inventory/office
	ansible/office.yml
	ssh-config-hosts
请在切换分支前提交或贮藏您的修改。
正在终止
```

### **问题处理:**

当我们需要更新本地分支代码，遇到以上的报错，可以通过 `git stash` 将未提交的修改保存到一个临时的区域。然后我们再进行 `git fetch` 更新本地代码就可以正常使用了. 在完成更新操作之后，我们再使用`git stash apply` 最近的 stash 应用到工作目录.

