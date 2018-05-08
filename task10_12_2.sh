#!bin/bash

dir="$(cd "$(dirname "$0")" && pwd)"

mkdir $dir/etc
export $(grep -v '#' $dir/config)

envsubst < tmp/docker-compose.yml > $dir/docker-compose.yml
envsubst < tmp/nginx.conf > $dir/etc/nginx.conf
mkdir -p ${NGINX_LOG_DIR}
mkdir $dir/certs
cd $dir/certs
openssl req -newkey rsa:2048 -nodes -keyout privateCA.key \
-subj /C=UA/O=Mirantis/CN=$HOST_NAME/emailAddress=. -out CA_csr.csr
openssl x509 -signkey privateCA.key -in CA_csr.csr \
-req -days 365 -out root-ca.crt
openssl genrsa -out nginx.web.key 2048
openssl req -new -key nginx.web.key \
-subj /C=UA/O=Mirantis/CN=$HOST_NAME/emailAddress=.  -out nginx.web.csr
openssl x509 -req \
-extfile <(printf "subjectAltName=IP:${EXTERNAL_IP},DNS:${HOST_NAME}") -days 365\
 -in nginx.web.csr -CA root-ca.crt\
 -CAkey privateCA.key -CAcreateserial -out web.crt
cat $dir/certs/web.crt $dir/certs/root-ca.crt > $dir/certs/web.pem

docker-compose up -d
