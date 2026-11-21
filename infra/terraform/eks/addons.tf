# ---------------------------------------------------------------------------
# AWS Load Balancer Controller (needed for ALB canary traffic shifting)
# ---------------------------------------------------------------------------
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 6.11"

  role_name                              = "${var.cluster_name}-aws-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.9.2"

  values = [yamlencode({
    clusterName = module.eks.cluster_name
    region      = var.region
    vpcId       = module.vpc.vpc_id

    serviceAccount = {
      name = "aws-load-balancer-controller"

      annotations = {
        "eks.amazonaws.com/role-arn" = module.lb_controller_irsa.iam_role_arn
      }
    }
  })]
}

# ---------------------------------------------------------------------------
# Argo CD, then the root app-of-apps. From here on, Git is the source of truth.
# ---------------------------------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  values = [yamlencode({
    configs = {
      params = {
        "server.insecure" = true # TLS terminates at the ingress / port-forward
      }
    }
    server = {
      replicas = 2
    }
    repoServer = {
      replicas = 2
    }
    applicationSet = {
      replicas = 2
    }
  })]

  depends_on = [helm_release.aws_lb_controller]
}

resource "helm_release" "argocd_root_app" {
  name       = "argocd-root-app"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"

  values = [yamlencode({
    applications = {
      root = {
        namespace  = "argocd"
        project    = "default"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]

        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = "main"
          path           = "argocd"

          directory = {
            recurse = true
            exclude = "bootstrap/*"
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
