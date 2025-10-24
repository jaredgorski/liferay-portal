
resource "helm_release" "ingress_nginx" {
	chart="ingress-nginx"
	create_namespace=false
	depends_on=[
		kubernetes_namespace.ingress_nginx,
	]
	name="nginx-ingress-controller"
	namespace=kubernetes_namespace.ingress_nginx.metadata[0].name
	repository="https://kubernetes.github.io/ingress-nginx"
	values=[
		<<-EOT
        controller:
            service:
                annotations:
                    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
                    service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
                    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
                    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
        EOT
	]
	version="4.13.3"
}
resource "kubernetes_namespace" "ingress_nginx" {
	metadata {
		name="nginx-ingress-controller"
	}
}