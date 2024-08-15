.PHONY: all check-aws-credentials deploy-infrastructure configure-ansible deploy-socks-shop deploy-monitoring clean

all: check-aws-credentials deploy-infrastructure configure-ansible deploy-socks-shop deploy-monitoring 

check-aws-credentials: 
	@if [ -z "$$AWS_ACCESS_KEY_ID"] || [-z "$$AWS_SECRET_ACCESS_KEY"]; then \
		if [ -f terraform/terraform.tfvars ]; then \
			access_key=$$(grep aws_access_key terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d '\n'); \
			secret_key=$$(grep aws_secret_key terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d '\n'); \
			if [ ! -z "$$access_key" ] && [ ! -z "$$secret_key" ]; then \
				export AWS_ACCESS_KEY_ID=$$access_key; \
				export AWS_SECRET_ACCESS_KEY=$$secret_key; \
				echo "AWS credentials loaded from terraform.tfvars"; \
			else \
				echo "AWS credentials not found in environment variables or terraform.tfvars."; \
				echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY or add them to terraform.tfvars."; \
				exit 1; \
			fi; \
		else \
			echo "AWS credentials not found or not found configured correctly."; \
			echo "Please run 'aws configure' to set up your AWS credentials."; \
			exit 1; \
		fi; \
	fi

deploy-infrastructure:
	cd terraform && terraform init && terraform apply -var-file=terraform.tfvars -auto-approve

configure-ansible:
	@echo "Configuring Ansible and kubeconfig..."
	@cluster_name=$$(cd terraform && terraform output -raw cluster_name); \
	region=$$(cd terraform && terraform output -raw region); \
	aws eks get-token --cluster-name $$cluster_name > kubeconfig_auth_token.json
	@kubectl apply -f kubeconfig_auth_token.json
	@aws eks update-kubeconfig --name $$(cd terraform && terraform output -raw cluster_name) --region $$(cd terraform && terraform output -raw region)
	@echo "export KUBECONFIG="~/kube/config" >> ~/.bashrc
	@echo "Ansible collections installation..."
	@ansible-galaxy collection install community.kubernetes kubernetes.core

deploy-socks-shop: configure-ansible 
	ansible-playbook k8s/deploy_socks_shop.yaml

deploy-monitoring: configure-ansible
	ansible-playbook k8s/deploy_monitoring.yaml

clean:
	cd terraform && terraform destroy -auto-approve
	rm -rf microservices-demo
	rm -f ~/.kube/config kubeconfig_auth_token.json

