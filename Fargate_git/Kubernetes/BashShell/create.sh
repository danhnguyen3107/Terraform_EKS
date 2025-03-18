#!/bin/bash

kubectl apply -f configmap-postgresql.yaml
kubectl apply -f secret-postgresql.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f blogapp-deployment.yaml
kubectl apply -f blogapp-service.yaml


