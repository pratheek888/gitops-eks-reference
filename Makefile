ENV ?= dev
CHART := charts/platform-app
SCHEMAS := -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

.PHONY: deps lint template validate tf-validate all

deps:
	helm dependency build $(CHART)

lint: deps
	helm lint charts/service
	helm lint $(CHART) -f $(CHART)/values.yaml -f environments/$(ENV)/values.yaml
	yamllint -c .yamllint.yaml argocd environments

template: deps
	helm template platform-app-$(ENV) $(CHART) --namespace platform-$(ENV) \
	  -f $(CHART)/values.yaml -f environments/$(ENV)/values.yaml

validate: deps
	$(MAKE) -s template ENV=$(ENV) | kubeconform -strict -summary $(SCHEMAS) -
	kubeconform -strict -summary $(SCHEMAS) argocd/

tf-validate:
	cd infra/terraform/eks && terraform fmt -check && terraform init -backend=false && terraform validate

all:
	for e in dev preprod prod; do $(MAKE) lint validate ENV=$$e || exit 1; done
	$(MAKE) tf-validate
