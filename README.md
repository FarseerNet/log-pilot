## 说明
这是来自阿里云的容器日志采集工具。https://github.com/AliyunContainerService/log-pilot

由于官方不再维护这个版本，只支持到es 6.x。
本镜像经修改后，支持es 7x的版本。

# 源码、镜像
https://hub.docker.com/r/farseernet/log-pilot

https://github.com/FarseerNet/log-pilot

## 使用
首先：在应用容器中，需要定义env
```
aliyun_logs_$Name=stdout  # $Name=elasticsearch index
aliyun_logs_$Name_format=json # 如果是使用.net程序的朋友，建议使用json方式输出日志格式，借助Farseer.net组件的日志模块：IocManager.Instance.Logger 日志，则默认使用json方式

#示例：
aliyun_logs_farseer=stdout
aliyun_logs_farseer_format=json
```
## K8S部署yaml文件

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-pilot
  labels:
    app: log-pilot
    k8s.kuboard.cn/layer: cloud
spec:
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: log-pilot
  template:
    metadata:
      name: log-pilot
      labels:
        app: log-pilot
    spec:
      # 是否允许部署到Master节点上
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      containers:
        - name: log-pilot
          image: farseernet/log-pilot:7.x
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 200m
              memory: 200Mi
          securityContext:
            capabilities:
              add:
                - SYS_ADMIN
          envFrom: #以密文的方式，把配置项写到env
            - secretRef:
                name: log-pilot
          env:
            - name: "NODE_NAME"
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          volumeMounts:
            - name: sock
              mountPath: /var/run/docker.sock
            - name: root
              mountPath: /host
              readOnly: true
            - name: varlib
              mountPath: /var/lib/filebeat
            - name: varlog
              mountPath: /var/log/filebeat
            - name: localtime
              mountPath: /etc/localtime
              readOnly: true
      volumes:
        - name: sock
          hostPath:
            path: /var/run/docker.sock
        - name: root
          hostPath:
            path: /
        - name: varlib
          hostPath:
            path: /var/lib/filebeat
            type: DirectoryOrCreate
        - name: varlog
          hostPath:
            path: /var/log/filebeat
            type: DirectoryOrCreate
        - name: localtime
          hostPath:
            path: /etc/localtime
---
apiVersion: v1
data:
  LOGGING_OUTPUT: ZWxhc3RpY3NlYXJjaA== #elasticsearch
  ELASTICSEARCH_HOSTS: aHR0cDovL2VzOjgw #es (必填) http://es:80
  ELASTICSEARCH_USER: "" #es (选填) username
  ELASTICSEARCH_PASSWORD: "" #es (选填) pwd
  ELASTICSEARCH_PATH: "" #es (选填) http path prefix
  ELASTICSEARCH_SCHEME: "" #es (选填) scheme, default is http
kind: Secret
metadata:
  name: log-pilot
  namespace: default
type: Opaque
```
> ES的配置在密文log-pilot配置中，请自行修改ES HOST
 
## 最后
只要成功在K8S中部署好log-pilot，配置好ES HOST，并在您的POD中，定义好env标签。那么log-pilot就开始工具了，可以利用kibana去查看这些信息。

如果使用.net core的朋友，默认使用ILogger组件打印的日志消息并不太友好的显示在ES中（日志内容格式化问题），在这里推荐使用我的另一个开源框架：Farseer.Net。并使用IocManager.Instance.Logger模块进行打印日志（默认配置好适合log-pilot采集所需的格式体）IocManager.Instance.Logger仅是修改了微软日志组件的输出格式，并不依赖第三方组件。
