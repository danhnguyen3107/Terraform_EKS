#!/bin/bash

kubectl delete deployment blogapp-deployment postgres-deployment --namespace=default

kubectl delete service blogapp-service postgres-service --namespace=default


kubectl delete configmap blogapp-config --namespace=default

kubectl delete secret blogapp-secrets --namespace=default





