# pod-running-checker

Useful as InitContainer in Kubernetes to create dependendencies between deployments, as it could check if another deployment is `Running` by matching labels and status, before starting to rollout the dependency

It will check for pods running with certain labels
```
LABELS="app=alpine,pod-template-hash=7b421232"
```

It supports for WAIT_TIME and default is 10 seconds
```
WAIT_TIME=10
```
