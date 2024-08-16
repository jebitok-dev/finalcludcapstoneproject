.PHONY: all deploy-all check-aws-credentials deploy-infrastructure configure-ansible deploy-socks-shop deploy-monitoring clean

all: check-aws-credentials deploy-infrastructure configure-ansible deploy-socks-shop deploy-monitoring 
deploy-all: deploy_socks_shop deploy_monitoring

check-aws-credentials: 
	@echo "Checking for AWS credentials..."
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ]; then \
		echo "AWS credentials not found in environment variables."; \
		echo "Checking terraform.tfvars file..."; \
		if [ -f terraform/terraform.tfvars ]; then \
			export AWS_ACCESS_KEY_ID=$$(grep aws_access_key terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d '\n'); \
			export AWS_SECRET_ACCESS_KEY=$$(grep aws_secret_key terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d '\n'); \
			if [ -z "$$AWS_ACCESS_KEY_ID" ] && [ -z "$$AWS_SECRET_ACCESS_KEY" ]; then \
				echo "AWS credentials not found in terraform.tfvars."; \
				echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables or add them to terraform.tfvars."; \
				exit 1; \
			else \
				echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables."; \
				exit 1; \
			fi; \
		else \
			echo "terraform.tfvars file not found"; \
		fi; \
	else \
		echo "AWS credentials found in environment variables"; \
	fi
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ]; then \
		echo "AWS credentials are missing or incomplete"; \
		echo "Please ensure both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set"; \
		exit 1; \
	fi
	@echo "Validating AWS credentials..."
	@if ! aws sts get-caller-identity >/dev/null 2>&1; then \
		echo "Failed to validate AWS credentials. Please check your credentials and permissions."; \
		exit 1; \
	fi
	@echo "AWS credentials are valid."

deploy-infrastructure: export AWS_ACCESS_KEY_ID:=$(AWS_ACCESS_KEY_ID)
deploy-infrastructure: export AWS_SECRET_ACCESS_KEY:=$(AWS_SECRET_ACCESS_KEY)
deploy-infrastructure:
	cd terraform && terraform init && terraform apply -var-file=terraform.tfvars -auto-approve

configure-ansible: export AWS_ACCESS_KEY_ID:=$(AWS_ACCESS_KEY_ID)
configure-ansible: export AWS_SECRET_ACCESS_KEY:=$(AWS_SECRET_ACCESS_KEY)
configure-ansible: check-aws-credentials
	@echo "Configuring Ansible and kubeconfig..."
	@echo "Checking AWS CLI configuration..."
	@aws --version || (echo "AWS CLI not found. Please install it."; exit 1)
	@echo "Current AWS Region: $$(aws configure get region)"
	@if [ -z "$$(aws configure get region)" ]; then \
		echo "AWS region is not set. Please set it using 'aws configure set region your-region'"; \
		exit 1; \
	fi
	@echo "Checking Terraform outputs..."
	@cd terraform && \
	cluster_name=$$(terraform output -raw cluster_name 2>/dev/null) && \
	region=$$(terraform output -raw region 2>/dev/null) && \
	if [ -z "$$cluster_name" ] || [ -z "$$region" ]; then \
		echo "Error: Required Terraform outputs not found. Have you run 'terraform apply'?"; \
		echo "Cluster Name: $$cluster_name"; \
		echo "Region: $$region"; \
		exit 1; \
	fi && \
	echo "Cluster Name: $$cluster_name" && \
	echo "Region: $$region" && \
	echo "Updating kubeconfig..." && \
	if ! aws eks update-kubeconfig --name $$cluster_name --region $$region; then \
		echo "Failed to update kubeconfig. Check your AWS credentials and permissions."; \
		exit 1; \
	fi
	@echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
	@echo "Ansible collections installation..."
	@if ! ansible-galaxy collection install community.kubernetes kubernetes.core; then \
		echo "Failed to install Ansible collections. Check if Ansible is installed."; \
		exit 1; \
	fi
	@echo "Verifying cluster access..."
	@if ! kubectl get nodes; then \
		echo "Failed to access the cluster. Please check your network settings and security groups."; \
		exit 1; \
	fi

deploy_socks_shop: export AWS_ACCESS_KEY_ID:=$(AWS_ACCESS_KEY_ID)
deploy_socks_shop: export AWS_SECRET_ACCESS_KEY:=$(AWS_SECRET_ACCESS_KEY)
deploy-socks-shop: configure-ansible 
	ansible-playbook -vvv --connection=local k8s/deploy_socks_shop.yaml

deploy_monitoring: export AWS_ACCESS_KEY_ID:=$(AWS_ACCESS_KEY_ID)
deploy_monitoring: export AWS_SECRET_ACCESS_KEY:=$(AWS_SECRET_ACCESS_KEY)
deploy-monitoring: configure-ansible
	ansible-playbook -vvv k8s/deploy_monitoring.yaml

clean:
	cd terraform && terraform destroy -auto-approve
	rm -rf microservices-demo
	rm -f ~/.kube/config kubeconfig_auth_token.json

