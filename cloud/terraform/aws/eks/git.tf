resource "kubernetes_namespace" "gitea" {
	metadata {
		name = "gitea"
	}
}

resource "helm_release" "gitea" {
	chart      = "gitea"
	depends_on = [
		kubernetes_namespace.gitea
	]
	name       = "gitea"
	namespace  = kubernetes_namespace.gitea.metadata[0].name
	repository = "https://dl.gitea.io/charts/"
	version    = "9.0.0"
	values = [
		<<-EOT
    gitea:
      admin:
        username: gitea-admin
        # Please change this default password
        password: StrongPassword123!
    EOT
	]
}

# TODO: Add resources to bootstrap the git repository with data files.
# This could be a kubernetes_job resource that runs a git clone, adds files, and pushes them.
