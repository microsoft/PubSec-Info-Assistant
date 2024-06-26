# Initialize variables with a default value
name=myapp
tag=latest
folder=./artifacts/myapp

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--name) # Look for the -n or --name option
            if [[ -n $2 && $2 != -* ]]; then
                name=$2
                shift # Move past the argument value
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -t|--tag) # Look for the -t or --tag option
            if [[ -n $2 && $2 != -* ]]; then
                tag=$2
                shift # Move past the argument value
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -f|--folder) # Look for the -f or --folder option
            if [[ -n $2 && $2 != -* ]]; then
                folder=$2
                shift # Move past the argument value
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        *) # Handle any unrecognized options
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift # Move to the next argument
done

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"

# Function to get the digest of a file
function get_digest {
  sha256sum $1 | awk '{print $1}'
}
 
# Function to initiate blob upload
function initiate_upload {
  curl -s -D - -X POST "https://$CONTAINER_REGISTRY/v2/$name/blobs/uploads/" -H "Authorization: Basic $base64creds" | grep -i location | awk '{print $2}' | tr -d '\r'
}
 
# Function to upload blob chunk
function upload_chunk {
  local location=$1
  local chunk=$2
  local range=$3
  local length=$4
  curl  -s -D - -X PATCH "https://$CONTAINER_REGISTRY$location" -H "Content-Type: application/octet-stream" -H "Content-Range: $range" -H "Content-Length: $length" -H "Authorization: Basic $base64creds" --data-binary @"$chunk" | grep -i location | awk '{print $2}' | tr -d '\r'
}
 
# Function to complete blob upload
function complete_upload {
  local location=$1
  local digest=$2
  curl -s -D - -G -X PUT "https://$CONTAINER_REGISTRY$location" -H "Authorization: Basic $base64creds" \
  --data "digest=sha256:$digest"
}
 
function config_upload {
  local location=$1
  local digest=$2
  local config=$3
 
curl -s -X POST "https://$CONTAINER_REGISTRY/v2/$name/blobs/uploads/?digest=sha256:$digest" -H "Authorization: Basic $base64creds" -H "Content-Type: application/octet-stream" --data-binary @"$config" 
}
 
# Function to upload a layer    
function upload_layer {  
  local layer=$1  
  echo "Uploading layer $layer"  
  # 1. Initiate the upload  
  local location=$(initiate_upload)  
  if [ -z "$location" ]; then  
    echo "Failed to initiate upload for $layer"  
    exit 1  
  fi  
  # 2. Upload the layer using PATCH  
  local offset=0  
  local chunk_size=10485760 
  while [ $offset -lt $(stat -c%s "$layer") ]; do  
    echo "Uploading chunk $offset"  
    local chunk="${layer}.chunk"  
    dd if="$layer" of="$chunk" skip=$((offset / chunk_size)) bs=$chunk_size count=1 status=none  
    local range="$offset-$((offset + $(stat -c%s "$chunk") - 1))"  
    local length=$(stat -c%s "$chunk")  
    local upload_response=$(upload_chunk "$location" "$chunk" "$range" "$length")  
    location=$upload_response  
    if [ -z "$location" ]; then  
      echo "Failed to upload chunk for $layer"  
      exit 1  
    fi  
    offset=$((offset + chunk_size))  
    rm "$chunk"  
  done  
  # 3. Complete the upload  
  local digest=$(get_digest "$layer")  
  local complete_response=$(complete_upload "$location" "$digest")  
  if echo "$complete_response" | grep -q "error"; then  
    echo "Failed to complete upload for $layer"  
    exit 1  
  fi  
  echo "Layer $layer uploaded successfully"  
}

cd $folder
base64creds=$(echo -n "${CONTAINER_REGISTRY_USERNAME}:${CONTAINER_REGISTRY_PASSWORD}" | base64)

# Read layers from digest
# Read index.json to get the manifest digest  
echo "Looking for manifest digest in index.json in $folder"
manifest_digest=$(jq -r '.manifests[0].digest' index.json)  
echo "Manifest Digest: $manifest_digest"  
# Get the manifest blob name  
manifest_blob_name=${manifest_digest#*:}  
echo "Manifest Blob Name: $manifest_blob_name"  
# Extract the manifest blob  
manifest_file="blobs/sha256/$manifest_blob_name"  
if [ ! -f "$manifest_file" ]; then  
    echo "Manifest file not found: $manifest_file"  
    exit 1  
fi  

raw_layers=$(jq -r '.layers[].digest' $manifest_file)
layers=()
for raw_layer in $raw_layers; do
    layer="blobs/sha256/${raw_layer:7}"
    layers+=($layer)
done
echo "Layers: ${layers[@]}"

# Upload layers in parallel  put cap on max degree of parallelism to 3
for layer in "${layers[@]}"; do  
  upload_layer "$layer" &  
done  
# Wait for all background jobs to complete  
wait  
 
# Upload the config file
config=$(jq -r '.config.digest' $manifest_file)
config_digest=$(get_digest ./blobs/sha256/${config:7})
 
config_response=$(config_upload "$location" "$config_digest" "$config")
echo "Config uploaded"
if echo "$config_response" | grep -q "error"; then
 echo "Failed to upload config"
 exit 1
fi
 
# Push the image manifest
manifest_response=$(curl -s -D - -X PUT "https://$CONTAINER_REGISTRY/v2/$name/manifests/$tag" -H "Content-Type: application/vnd.oci.image.manifest.v1+json" -H "Authorization: Basic $base64creds" --data-binary @$manifest_file)
echo "Manifest uploaded"
if echo "$manifest_response" | grep -q "error"; then
echo "Failed to upload manifest"
exit 1
fi
 
echo "Image pushed successfully"