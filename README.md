# pod-running-checker

## Description

A POSIX shell script based container: It that calls the Kubernetes API to check running Pods matching the desired Labels.

## Purpose

Useful as InitContainer in Kubernetes to create dependendencies between deployments, as it could check if another deployment is `Running` by matching labels and status, before starting to rollout the dependency

It will check for pods running with certain labels
```
LABELS="app=alpine,pod-template-hash=7b421232"
```

It supports for WAIT_TIME and default is 10 seconds
```
WAIT_TIME=10
```

It will not time out, useful to keep the default timeout of a deplomyent or a `helm update`

## Cluster Permissions

In order to be able to operate, this pod needs to have some permissions and query the Kubernetes API, this could be done by creating a Service Account and Cluster Role

Is already a deprecrated way to use ClusterRole and ClusterRoleBinding since v1.17

Be aware about the namespace where you define it

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-running-checker
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: pod-running-checker
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - services
      - endpoints
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: system:serviceaccount:pod-running-checker:default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-running-checker
subjects:
- kind: ServiceAccount
  name: pod-running-checker
  namespace: default
```

## Deployment example
This `nginx-deployment` will rollout when at least one Pod with labels `app=alpine` and `pod-template-hash=7b421232` is on `Running` state


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      serviceAccountName: pod-running-checker
      initContainers:
        - name: pod-running-checker
          securityContext:
            {}
          image: piscue/pod-running-checker:0.1.2
          imagePullPolicy: IfNotPresent
          env:
            - name: LABELS
              value: "app=alpine,pod-template-hash=7b421232"
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
```
