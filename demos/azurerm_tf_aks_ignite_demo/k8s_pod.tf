
# Set up the provider for k8s
provider "kubernetes" {
  host = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"

  #username               = "${azurerm_kubernetes_cluster.k8s.kube_config.0.username}"
  #password               = "${azurerm_kubernetes_cluster.k8s.kube_config.0.password}"

  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)}"
}

# Create the k8s nginx pod
resource "kubernetes_pod" "ignite-pod" {
  metadata {
    name = "ignite-k8s-nginx-demo"

    labels {
      name = "nginx"
    }
  }

  spec {
    container {
      image = "nginx:1.7.9"
      name  = "nginx"
    }
  }
}

# Create the k8s nginx web service
resource "kubernetes_service" "ignite-web" {
  metadata {
    name = "ignite-k8s-nginx-demo"
  }

  spec {
    selector {
      name = "${kubernetes_pod.ignite-pod.metadata.0.labels.name}"
    }

    session_affinity = "ClientIP"

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
