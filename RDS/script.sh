#!/bin/bash

#TODO: Se debe realizar el cambio antes del despliegue

# CONFIG_FILE=${2:-config.ini}
# . $CONFIG_FILE

MASTER_USERNAME='AdminIgnite'
MASTER_USERPASSWORD='T00RR3N3GR42023'
DBCLUSTER_IDENTIFIER='DB-SERVERLESS-V2'
ENGINE='aurora-postgresql'
ENGINE_VERSION='14.7'
MIN_CAPACITY='1'
MAX_CAPACITY='4'
COID='TORRENEGRA'
ASSETID='0010'
APID='CURSO01'
ENV='DEV'
MN='00'
RETENTION_INDAYS=30
BUCKET=`echo "$COID-$ASSETID-$APID-$ENV-$MN" | awk '{print tolower($0)}'`
STACK_NAME="${COID}-${ASSETID}-${APID}-${ENV}-${MN}"
PROJECT_NAME="${COID}-${ASSETID}-${APID}"
DATABASE_NAME="ignite-db"

PARAMETERS="ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
            ParameterKey=ENV,ParameterValue=$ENV \
            ParameterKey=MN,ParameterValue=$MN \
            ParameterKey=Bucket,ParameterValue=$BUCKET \
            ParameterKey=DatabaseName,ParameterValue=$DATABASE_NAME \
            ParameterKey=MasterUsername,ParameterValue=$MASTER_USERNAME \
            ParameterKey=MasterUserPassword,ParameterValue=$MASTER_USERPASSWORD \
            ParameterKey=DBClusterIdentifier,ParameterValue=$DBCLUSTER_IDENTIFIER \
            ParameterKey=Engine,ParameterValue=$ENGINE \
            ParameterKey=EngineVersion,ParameterValue=$ENGINE_VERSION \
            ParameterKey=MinCapacity,ParameterValue=$MIN_CAPACITY \
            ParameterKey=MaxCapacity,ParameterValue=$MAX_CAPACITY"

sync_templates() {
  aws s3 sync ./ s3://$BUCKET/templates/ --exclude ".git/*" --exclude "*.ini" --exclude ".sh" --delete
}

show_help() {
  echo "Usage: chmod +x script.sh"
  echo "  ./script -h     display this help message"
  echo "  ./script sync   Sync files"
  echo "  ./script create Create the stack"
  echo "  ./script update Update the stack"
  echo "  ./script cs     Create a change set"
  echo "  ./script cs     Delete resources of STACK"
}
 
create_arch() {
  TEST=`aws s3 ls | grep "$BUCKET\$" | wc -l`
  if [ "$TEST" == "0" ]; then
    aws s3 mb s3://$BUCKET || exit 0
  fi
  aws s3 mb s3://$BUCKET
  aws s3api put-bucket-cors --bucket $BUCKET --cors-configuration '{"CORSRules" : [{"AllowedHeaders":["*"],"AllowedMethods":["GET","PUT", "POST", "DELETE", "HEAD"],"AllowedOrigins":["*"],"ExposeHeaders":["ETag"]}]}'
  sync_templates;
  aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://main.cf.yaml --capabilities CAPABILITY_NAMED_IAM --parameters $PARAMETERS
}

update_arch() {
  aws s3api put-bucket-cors --bucket $BUCKET --cors-configuration '{"CORSRules" : [{"AllowedHeaders":["*"],"AllowedMethods":["GET","PUT", "POST", "DELETE", "HEAD"],"AllowedOrigins":["*"],"ExposeHeaders":["ETag"]}]}'
  sync_templates;
  aws cloudformation update-stack --stack-name $STACK_NAME --template-body file://main.cf.yaml --capabilities CAPABILITY_NAMED_IAM --parameters $PARAMETERS
}

create_change_set() {
  sync_templates;
  aws cloudformation create-change-set --change-set-name update --stack-name $STACK_NAME --template-body file://main.cf.yaml --capabilities CAPABILITY_NAMED_IAM --parameters $PARAMETERS
}

delete_arch(){
  sync_templates;
  aws s3 rm s3://$BUCKET --recursive
  aws cloudformation delete-stack --stack-name $STACK_NAME
}

case ${1} in
  "-h" | "--help" ) show_help; ;;
  "sync") sync_templates; ;;
  "create") create_arch;  ;;
  "update") update_arch; ;;
  "cs") create_change_set; ;;
  "delete" | "--d" ) delete_arch; ;;
esac
