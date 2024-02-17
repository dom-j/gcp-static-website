# GCP-static-website

## Architecture

![Reference image](/assets/GCP-static-website-plan-Terraform.png) 



This project is a Terraform configuration that creates a static website on Google Cloud Platform.

Prerequisites

To use this project, you will need the following:

* A Google Cloud Platform project
* The Terraform CLI

## Getting Started

#### 1. To get started, clone the project repository to your local machine:

`git clone https://github.com/GoogleCloudPlatform/terraform-google-static-website.git`

#### 2. Once you have cloned the repository, change directory to the project directory:

`cd terraform-google-static-website`


#### 3. Configuring the Project

Before you can create the static website, you will need to configure the project. To do this, edit the main.tf file and provide the following values:

* project_id - The ID of your Google Cloud Platform project
* bucket_name - The name of the Cloud Storage bucket that you want to use for your static website
* index_page - The name of the index page for your static website
* error_page - The name of the error page for your static website

#### 4. Creating the Static Website

Once you have configured the project, you can create the static website by running the following command:

`terraform apply`

Terraform will then create the following resources:

* A Cloud Storage bucket
* An IAM policy binding that grants the storage.objectViewer role to the allUsers group
* An HTTP load balancer

#### 5. Testing the Static Website

Once the static website has been created, you can test it by visiting the following URL:

https://www.example.com

#### Troubleshooting

If you encounter any problems with this project, please refer to the following resources:

* The Terraform documentation
* The Google Cloud Platform documentation
* The Google Cloud Platform support forums