#!/bin/bash

kubectl delete deployment blogapp-deployment 

kubectl delete statefulset postgres-deployment 

#kubectl delete deployment postgres-deployment --namespace=default

kubectl delete service blogapp-service
kubectl delete service postgres-service 

kubectl delete configmap blogapp-config 

kubectl delete secret blogapp-secrets 



kubectl delete PersistentVolume local-postgres-pv
kubectl delete PersistentVolumeClaim postgres-pvc
kubectl delete StorageClass local-storage



