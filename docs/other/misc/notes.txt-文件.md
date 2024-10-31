# NOTES.txt 文件

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/helm/templates/notes_files.md "编辑此页")

# NOTES.txt 文件

在本节中我们将来了解为 chart 用户提供说明的一个 `NOTES.txt` 文件，在 chart 安装或者升级结束时，Helm 可以为用户打印出一些有用的信息，使用模板也可以自定义这些信息。

要将安装说明添加到 chart 中，只需要创建一个 `templates/NOTES.txt` 文件，该文件纯文本的，但是可以像模板一样进行处理，并具有所有常规模板的功能和可用对象。

现在让我们来创建一个简单的 `NOTES.txt` 文件：
    
    
    Thank you for installing {{ .Chart.Name }}.
    
    Your release is named {{ .Release.Name }}.
    
    To learn more about the release, try:
    
      $ helm status {{ .Release.Name }}
      $ helm get {{ .Release.Name }}
    

现在我们运行 `helm install ./mychart`，我们就可以在底部看到这样的消息：
    
    
    RESOURCES:
    ==> v1/Secret
    NAME                   TYPE      DATA      AGE
    rude-cardinal-secret   Opaque    1         0s
    
    ==> v1/ConfigMap
    NAME                      DATA      AGE
    rude-cardinal-configmap   3         0s
    
    
    NOTES:
    Thank you for installing mychart.
    
    Your release is named rude-cardinal.
    
    To learn more about the release, try:
    
      $ helm status rude-cardinal
      $ helm get rude-cardinal
    

用这种方式可以向用户提供一个有关如何使用其新安装的 chart 的详细信息，强烈建议创建 `NOTES.txt` 文件，虽然这不是必须的。
