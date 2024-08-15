# Infrastructure as Code Project


## SetUp Project Locally 

`````
$ git clone 
$ cd 
`````

## Run/ Test Project 

### Terraform
This project uses a `terraform.tfvars` file to manage aws environment variables. 

- To setup copy `example.terraform.tfvars` to a new file `terraform.tfvars` then replace with your actual AWS credentials and other configurations. 

``````
$ cp example.terraform.tfvars terraform.tfvars
// then update the file with your own credentials

`````` 

- Ensure `terraform.tfvars` is added into the `.gitignore` to prevent committing sensitive information.

``````
$ source .env
// Get-Content .env | ForEach-Object { $var = $_.Split('='); Set-Item "env:$($var[0])" $var[1] }

$ terraform init 
$ terraform plan -var-file=terraform.tfvars
$ terraform apply 
$ terraform destroy
``````

- [Cluster Endpoint](https://D84029D5729C47C9238420156FE69C53.gr7.us-east-1.eks.amazonaws.com)

### Kubernetes

``````
$ make deploy-infrastructure
$ make deploy-socks-shop
$ make deploy-monitoring
$ make all
$ make clean
``````

``````
$ ansible-vault encrypt secrets.yml
// to deploy the Socks Shop to Cluster 
$ kubectl apply -f socks-shop-deployment.yaml
``````




## Acknowledgement 
I acknowledge [ALTSchool Africa](https://engineering.altschoolafrica.com/programs/cloud-engineering) for the Diploma in Cloud Engineering course that it has offered us over the last year and the quality instructors and resources that has helped us curate this project and skills we have gained.