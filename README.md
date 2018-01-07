# k8surfer

## install nginx ingress
helm init
kubectl run echoserver --image=gcr.io/google_containers/echoserver:1.4 --port=8080 --namespace default
kubectl expose deployment echoserver --type=ClusterIP

helm upgrade --install nginx-ingress stable/nginx-ingress --namespace default -f aws/values_nginx-ingress.yml
kubectl apply -f aws/ingress_nginx-ingress.yml

you should see an external AWS URI, e.g. https://a57f206d8f0ca11e7b93f020c644f020-730344177.eu-central-1.elb.amazonaws.com/

helm upgrade --install kube-lego stable/kube-lego --namespace default -f aws/values_kube-lego.yml
kubectl get pods --all-namespaces -l app=ingress-nginx --watch

kubectl delete secret echoserver-tls

kubectl patch svc ingress-example-joomla --type='json' -p '[{"op":"remove","path":"/spec/ports/0/nodePort"},{"op":"remove","path":"/spec/ports/1/nodePort"},{"op":"replace","path":"/spec/type","value":"ClusterIP"}]'
curl -vvv -L -k -H "Host: lab-cluster.kubeland.cc" https://a57f206d8f0ca11e7b93f020c644f020-730344177.eu-central-1.elb.amazonaws.com

## install gitlab
helm repo add lwolf-charts http://charts.lwolf.org
curl https://raw.githubusercontent.com/lwolf/gitlab-chart/master/gitlab/values.yaml -o aws/values_gitlab.yaml
helm upgrade --install git lwolf-charts/gitlab --namespace default -f aws/values_gitlab.yml

## install sonarqube
helm upgrade --install sonarqube stable/sonarqube --namespace default -f aws/values_sonarqube.yml



minikube dashboard
minikube addons open heapster


## Sonstiges
### gitlab sign-in reset
$ sudo -u git -H bundle exec rails console production
-> ApplicationSetting.last.update_attributes(signin_enabled: true)

# get init data
echo "GITLAB_ROOT_PASSWORD: $(kubectl get secret --namespace default git-gitlab -o jsonpath="{.data.GITLAB_ROOT_PASSWORD}" | base64 --decode)"
echo "GITLAB_SECRETS_DB_KEY_BASE: $(kubectl get secret --namespace default git-gitlab -o jsonpath="{.data.GITLAB_SECRETS_DB_KEY_BASE}" | base64 --decode)"
echo "GITLAB_SECRETS_SECRET_KEY_BASE: $(kubectl get secret --namespace default git-gitlab -o jsonpath="{.data.GITLAB_SECRETS_SECRET_KEY_BASE}" | base64 --decode)"
echo "GITLAB_SECRETS_OTP_KEY_BASE: $(kubectl get secret --namespace default git-gitlab -o jsonpath="{.data.GITLAB_SECRETS_OTP_KEY_BASE}" | base64 --decode)"


## TODO
projekt init und pullen
runner einrichten
echo-service spring boot basteln
gitlab runner einrichten
echo service bauen
metriken einsammeln
metriken in s3 bucket
quicksight auf s3 bucket
sonarqube configmap
gitlab configmap
