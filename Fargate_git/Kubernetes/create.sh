#!/bin/bash

aws eks update-kubeconfig --region us-west-1 --name eks-cluster

kubectl apply -f configmap-postgresql.yaml
kubectl apply -f secret-postgresql.yaml

kubectl apply -f postgres-deployment.yaml
# kubectl apply -f postgres-statefulset.yaml
kubectl apply -f postgres-service.yaml

# kubectl apply -f blogapp-deployment.yaml
# kubectl apply -f blogapp-service.yaml

# kubectl apply -f persistentvolume.yaml
# kubectl apply -f storageclass.yaml
# kubectl apply -f persistentvolumeclaim.yaml


# kubectl apply -f serviceAccount-eks.yaml
# kubectl apply -f ingress-controller.yaml