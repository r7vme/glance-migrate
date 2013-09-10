#!/bin/bash

IMAGE_NAME=$1

SRC_GLANCE='192.168.122.101'
DST_GLANCE='192.168.122.102'

OS_USERNAME=${2:-'admin'}
OS_PASSWORD=${3:-'nova'}
OS_TENANT_NAME=${4:-'admin'}

src-auth () {
$1 --os-username $OS_USERNAME \
   --os-password $OS_PASSWORD \
   --os-tenant-name $OS_TENANT_NAME \
   --os-auth-url "http://$SRC_GLANCE:5000/v2.0/" \
   ${@:2}
}

dst-auth () {
$1 --os-username $OS_USERNAME \
   --os-password $OS_PASSWORD \
   --os-tenant-name $OS_TENANT_NAME \
   --os-auth-url "http://$DST_GLANCE:5000/v2.0/" \
   ${@:2}
}

[ -z $IMAGE_NAME ] && echo "Usage: glance-migrate.sh <image-name> [<user> <pass> <tenant>]" && exit 1

META=`src-auth glance image-show $IMAGE_NAME`

DISK_FORMAT=`grep "disk_format" <<< "$META"|awk '{print $4}'`
CONTAINER_FORMAT=`grep "container_format" <<< "$META"|awk '{print $4}'`
IS_PUBLIC=`grep "is_public" <<< "$META"|awk '{print $4}'`
SIZE=`grep "size" <<< "$META"|awk '{print $4}'`

echo "Migrating image: "$IMAGE_NAME" from $SRC_GLANCE to $DST_GLANCE ..."
src-auth glance image-download $IMAGE_NAME | \
dst-auth glance image-create --name $IMAGE_NAME \
                       --disk-format $DISK_FORMAT \
                       --container-format $CONTAINER_FORMAT \
                       --is-public $IS_PUBLIC \
                       --size $SIZE > /dev/null
echo "Success!"
