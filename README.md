## 说明
这是来自阿里云的容器日志采集工具。https://github.com/AliyunContainerService/log-pilot

由于官方不再维护这个版本，只支持到es 6.x。
本镜像经修改后，支持es 7x的版本。

# 源码、镜像
https://hub.docker.com/r/farseernet/log-pilot

https://github.com/FarseerNet/log-pilot

## 使用
在应用容器中，需要定义env
```
aliyun_logs_$Name=stdout
```
其中，$Name=elasticsearch index

示例：
```
aliyun_logs_member=stdout
```
## K8S脚本

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
