#!/bin/bash
#
# Stores a file to a fraktal node

ACCOUNT_DIR="${HOME}/.eth-accounts"
RPC_URL="http://localhost:8545"
FILESTORE_URL="http://localhost:8542"

display_help() {
  echo "Usage: $0 [option...] " >&2
  echo "NOTE: Long form flags are not supported, but are listed here for reference"
  echo
  echo "   -h, --help                 display help"
  echo "   -f, --file <file>          file to store"
  echo "   -r, --rpc <url>            RPC URL (Default: http://localhost:8545)"
  echo "   -u, --filestore <url>      Filestore URL (Default: http://localhost:8542)"
  echo "   -a, --account-dir <dir>    account directory (Default: ${HOME}/.eth-accounts)"
  echo
  echo "Example: $0 -f ./my-file.txt"
}

while getopts ":hf:r:u:a:" opt; do
  case $opt in
    h)
      display_help
      exit 0
      ;;
    f)
      FILE=$OPTARG
      ;;
    r)
      RPC_URL=$OPTARG
      ;;
    u)
      FILESTORE_URL=$OPTARG
      ;;
    a)
      ACCOUNT_DIR=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      display_help
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$SCRIPT_DIR/..

if [ -z "$FILE" ]; then
  echo "File not specified"
  display_help
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

if [ ! -d "$ACCOUNT_DIR" ]; then
  echo "Account directory not found: $ACCOUNT_DIR"
  exit 1
fi

ACCOUNT_FILE=$(ls $ACCOUNT_DIR/UTC--* | head -n 1)

if [ ! -f "$ACCOUNT_FILE" ]; then
  echo "Account file not found in $ACCOUNT_DIR"
  exit 1
fi

ACCOUNT=$(cat $ACCOUNT_FILE | jq -r '.address')

echo "Storing file $FILE to fraktal node at $RPC_URL"

echo "Step 1 : Approving file hash on-chain (sha256sum)"
FILE_HASH=$(sha256sum $FILE | awk '{print $1}')
STRIPED_FILENAME=$(basename $FILE) #TODO: Only strip up to certain point in path ( ie address )
ACCOUNT_PASS=password go run ${WORK_DIR}/cmd/filestore/filestore.go approve --address $ACCOUNT --file $STRIPED_FILENAME --fileHash $FILE_HASH

echo "Step 2 : Uploading file to fraktal node"
PAYLOAD='{
  "address": "'$ACCOUNT'",
  "filepath": "'$STRIPED_FILENAME'"
}'
_payload="payload_json=$PAYLOAD"

curl -F "file=@$FILE" -F "$_payload" $FILESTORE_URL/upload

echo "Step 3 : Add file to fraktal node linked list"
ACCOUNT_PASS=password go run ${WORK_DIR}/cmd/filestore/filestore.go add --address $ACCOUNT --file $STRIPED_FILENAME

echo "Done"
