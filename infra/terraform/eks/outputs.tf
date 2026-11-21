output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "region" {
  value = var.region
}

output "configure_kubectl" {
  description = "Command to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "argocd_admin_password" {
  description = "Command to read the initial Argo CD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
