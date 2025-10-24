resource "helm_release" "gitea" {
	chart="gitea"
	depends_on=[
		kubernetes_namespace.gitea,
		kubernetes_secret.gitea_admin_auth,
		kubernetes_config_map.gitea_app_ini_config,
	]
	name="gitea"
	namespace=kubernetes_namespace.gitea.metadata[0].name
	repository="https://dl.gitea.com/charts"
	version="12.4.0"
	values=[
		<<-EOT
        gitea:
            additionalConfigSources:
                -   configMap:
                        name: ${kubernetes_config_map.gitea_app_ini_config.metadata[0].name}
            admin:
                existingSecret: ${kubernetes_secret.gitea_admin_auth.metadata[0].name}
                passwordMode: initialOnlyRequireReset

        global:
            storageClass: ${var.root_volume_type}

        ingress:
            className: "nginx"
            enabled: true
            hosts:
                -   host: ${var.gitea_hostname}
                    paths:
                        -   path: /
                            pathType: Prefix

        persistence:
            enabled: true

        postgresql:
            enabled: true
        postgresql-ha:
            enabled: false

        valkey:
            enabled: true
        valkey-cluster:
            enabled: false
        EOT
	]
}
resource "kubernetes_config_map" "gitea_app_ini_config" {
	depends_on=[
		kubernetes_namespace.gitea
	]
	data={
		database=<<-EOT
			DB_TYPE=postgres
		EOT
		indexer=<<-EOT
			ISSUE_INDEXER_TYPE=bleve
			REPO_INDEXER_ENABLED=true
		EOT
		server=<<-EOT
			APP_NAME="Gitea - ${var.deployment_name}"
		EOT
	}
	metadata {
		name="gitea-app-ini-config"
		namespace=kubernetes_namespace.gitea.metadata[0].name
	}
}
resource "kubernetes_namespace" "gitea" {
	metadata {
		name="gitea-system"
	}
}
resource "kubernetes_secret" "gitea_admin_auth" {
	depends_on=[
		kubernetes_namespace.gitea
	]
	data={
		password=random_password.gitea_admin_password.result
		username="admin"
	}
	metadata {
		name="gitea-admin-auth"
		namespace=kubernetes_namespace.gitea.metadata[0].name
	}
	type="Opaque"
}
resource "random_password" "gitea_admin_password" {
	length=16
	override_special="!#%&*()-_=+[]{}<>:?"
	special=true
}

# TODO: Add resources to bootstrap the git repository with data files.
# This could be a kubernetes_job resource that runs a git clone, adds files, and pushes them.
