#!/bin/bash
# Создаем директорию для пользователей
mkdir -p users && cd users

# Получаем путь к CA Minikube
MINIKUBE_CA_PATH=$(minikube docker-env | grep CA_CERT | cut -d'=' -f2 | tr -d '"')
MINIKUBE_CA_KEY_PATH="${MINIKUBE_CA_PATH%.*}.key"

# Создаем пользователей с группами
for user in admin editor viewer; do
  # Группа определяется по имени пользователя
  case $user in
    admin) group="admins" ;;
    editor) group="editors" ;;
    viewer) group="viewers" ;;
  esac

  # Генерируем ключ и CSR
  openssl genrsa -out $user.key 2048
  openssl req -new -key $user.key \
    -out $user.csr \
    -subj "/CN=$user/O=$group"
  
  # Подписываем сертификат CA Minikube
  openssl x509 -req -in $user.csr \
    -CA $MINIKUBE_CA_PATH \
    -CAkey $MINIKUBE_CA_KEY_PATH \
    -CAcreateserial \
    -out $user.crt -days 365
done

# Создаем kubeconfig для каждого пользователя
for user in admin editor viewer; do

  kubectl config set-credentials $user \
    --client-certificate=users/$user.crt \
    --client-key=users/$user.key \
    --kubeconfig=$user.kubeconfig

  kubectl config set-context $user-context \
    --cluster=minikube \
    --user=$user \
    --kubeconfig=$user.kubeconfig

done

echo "Пользователи созданы"
