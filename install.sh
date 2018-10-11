#!/bin/bash
#
# Create Kubernetes cluster on GCE using kube-up.sh
#
# This script should be run from the console on the GCP project where you want to
# have the cluster running on.
#
# Default list of kube-up options can be found here:
# https://github.com/kubernetes/kubernetes/blob/master/cluster/gce/config-default.sh

set -e

. ./config.sh

echo "Installing Kubernetes ${KUBERNETES_RELEASE} via kube-up.sh..."
curl -sS https://get.k8s.io | bash

#install kubectl
kubernetes_latest_release=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
echo "Installing kubectl ${kubernetes_latest_release} binary..."
curl -LO https://storage.googleapis.com/kubernetes-release/release/${kubernetes_latest_release}/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# get current context
context=`kubectl config current-context`

# get cluster name of context
name=`kubectl config get-contexts $context | awk '{print $3}' | tail -n 1`

# get endpoint of current context
endpoint=`kubectl config view -o jsonpath="{.clusters[?(@.name == \"$name\")].cluster.server}"`

# get cluster ip and instance name
external_ip=$(echo "$endpoint" | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' --only-match)
instance_name=$(gcloud compute instances list --filter EXTERNAL_IP=$external_ip --format="value(name)")

echo "Generating users..."

count=0
touch ./users.csv
while [[ $count -lt $USER_COUNT ]]
do
  user="user-${count}"
  password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10)
  echo "$password,$user,$user,\"$USER_GROUPS\"" >> ./users.csv
  count=$((count+1))
done

# Uncomment below to ppen public ports for NodePort services
gcloud compute firewall-rules create nodeport-rule --allow tcp:30000-32767

echo "Adding users to the basic auth file..."
gcloud compute scp --zone $KUBE_GCE_ZONE ./users.csv $instance_name:/tmp/users.csv

gcloud compute ssh ${KUBE_GCE_INSTANCE_PREFIX}-master --zone ${KUBE_GCE_ZONE} \
   --command "sudo /bin/sh -c 'cat /tmp/users.csv >> /etc/srv/kubernetes/basic_auth.csv'"

# Need to manually restart the api server... kube-up only run a pod without replicaset
echo "Restarting API Server..."
gcloud compute ssh ${KUBE_GCE_INSTANCE_PREFIX}-master --zone ${KUBE_GCE_ZONE} \
  --command "docker ps | grep k8s_kube-apiserver | cut -f1 -d ' ' | xargs docker restart"

echo "Setting up RBAC for every users..."

awk -F ',' '{system("cat ./rbac.yaml | namespace=" $2 " user=" $3 " envsubst | kubectl apply -f -")}' ./users.csv

# get CA certificate
echo "Retrieving ca.crt..."
gcloud compute ssh ${KUBE_GCE_INSTANCE_PREFIX}-master --zone ${KUBE_GCE_ZONE} \
  --command "sudo cp ${CERT_LOCATION} /tmp/ca.crt && sudo chown ${USER}:${USER} /tmp/ca.crt"

gcloud compute scp --zone $KUBE_GCE_ZONE $instance_name:/tmp/ca.crt .

echo "================================================================="

echo ""
echo "#"
echo "# Copy the following CA certificate and send it to every students"
echo "#"
echo ""
cat ./ca.crt

echo ""
echo "#"
echo "# User list"
echo "#"
echo ""
cat ./users.csv

echo ""
echo "----"
echo ""
echo "#"
echo "# Ask students to setup their environment via the following command"
echo "#"
echo ""
echo "$ kubectl config set-cluster workshop --server=$endpoint --certificate-authority=/path/to/ca.pem"
echo "$ kubectl config set-credentials workshop-user --username=user-<X> --password=<password>"
echo "$ kubectl config set-context workshop --cluster=workshop --user=workshop-user --namespace=user-<X>"
echo "$ kubectl config use-context workshop"
