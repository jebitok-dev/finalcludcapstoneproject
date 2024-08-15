.PHONY: all deploy-infrastructure deploy-socks-shop deploy-monitoring clean

all: deploy-infrastructure deploy-socks-shop deploy-monitoring 

deploy-infrastructure:
	cd terraform && terraform init && terraform apply -var-file=terraform.tfvars -auto-approve

deploy-socks-shop:
	ansible-playbook k8s/deploy_socks_shop.yaml

deploy-monitoring:
	ansible-playbook k8s/deploy_monitoring.yaml

clean:
	cd terraform && terraform destroy -auto-approve
	rm -rf microservices-demo