#!/bin/bash

# Copyright 2022 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

failure() {
    echo "========================================="
    echo "The Google Cloud setup was not completed."
    echo "Please fix the errors above!"
    echo "========================================="
    exit 0
}

# catch any error that happened during execution
trap 'failure' ERR

# Set the Google Cloud Project ID.
project_id=$1
echo "Project ID: $project_id"
gcloud config set project "$project_id"
export GOOGLE_PROJECT_ID=$GOOGLE_PROJECT_ID

# Create service account.
timestamp=$(date +%s)
service_account_id="service-acc-$timestamp"
echo "Service Account: $service_account_id"
gcloud iam service-accounts create "$service_account_id"

# Assign necessary roles to your new service account.
for role in {retail.admin,editor}
do
    gcloud projects add-iam-policy-binding "$project_id" --member="serviceAccount:$service_account_id@$project_id.iam.gserviceaccount.com" --role=roles/"${role}"
done
echo "Wait ~60 seconds to be sure the appropriate roles have been assigned to your service account"
sleep 60

# Upload your service account key file.
service_acc_email="$service_account_id@$project_id.iam.gserviceaccount.com"
gcloud iam service-accounts keys create ~/key.json --iam-account "$service_acc_email"

# Activate the service account using the key.
gcloud auth activate-service-account --key-file ~/key.json

# Set the key as the GOOGLE_APPLICATION_CREDENTIALS environment.
export GOOGLE_APPLICATION_CREDENTIALS=~/key.json

# Install necessary Google Cloud Retail libraries.
for service_dir in \
    {RetailEvents.Samples,RetailProducts.Samples,RetailSearch.Samples}
do
    path=~/cloudshell_open/dotnet-docs-samples/retail/interactive-tutorial/$service_dir
cd $path
    dotnet add package Google.Cloud.Retail.V2
    dotnet add package Google.Cloud.Storage.V1
done

echo "========================================="
echo "The Google Cloud setup is completed."
echo "Please proceed with the Tutorial steps"
echo "========================================="