#!/usr/bin/env bash
# modules/k8s/k8s.sh — kubernetes shortcuts
# prefix: k
# public: kgp kgs kgd kga klog kex kctx kns
#
# usage:
#   kgp                        kubectl get pods
#   kgp -o wide                extra kubectl flags pass through
#   kgs / kgd / kga            svc / deploy / all
#   klog mypod                 logs -f
#   kex mypod                  exec -it mypod -- sh
#   kex mypod bash             pick a shell
#   kctx                       current context
#   kctx minikube              switch context (this shell + kubectl)
#   kns                        current namespace (from config)
#   kns kube-system            switch namespace for later lazy k8s commands
#
# namespace/context come from config. pass -n / --context to override once.
# kns / kctx change the session so you don't have to.

# ── internals ────────────────────────────────────────

lazy_k8s_require() {
  if ! lazy_has kubectl; then
    lazy_error "kubectl is not installed"
    return 127
  fi
}

lazy_kubectl() {
  lazy_k8s_require || return $?

  if [ -n "${K8S_CONTEXT:-}" ] && ! lazy_has_flag --context "$@"; then
    set -- --context "$K8S_CONTEXT" "$@"
  fi

  if ! lazy_has_flag -n "$@" && ! lazy_has_flag --namespace "$@"; then
    set -- --namespace "${K8S_NAMESPACE:-default}" "$@"
  fi

  command kubectl "$@"
}

lazy_k8s_get() {
  local resource="$1"
  shift
  lazy_kubectl get "$resource" "$@"
}

lazy_k8s_logs() {
  if [ $# -eq 0 ]; then
    lazy_error "klog <pod>"
    return 2
  fi
  lazy_kubectl logs -f "$@"
}

# kex <pod> [shell] [args...]
lazy_k8s_exec() {
  local pod shell
  pod="${1:-}"
  if [ -z "$pod" ]; then
    lazy_error "kex <pod> [shell]"
    return 2
  fi
  shift

  if [ $# -eq 0 ]; then
    lazy_kubectl exec -it "$pod" -- sh
    return $?
  fi

  if lazy_is_flag "$1"; then
    lazy_kubectl exec -it "$pod" "$@"
    return $?
  fi

  shell="$1"
  shift
  lazy_kubectl exec -it "$pod" -- "$shell" "$@"
}

lazy_k8s_context() {
  lazy_k8s_require || return $?

  if [ $# -eq 0 ]; then
    command kubectl config current-context
    return $?
  fi

  command kubectl config use-context "$1" || return $?
  K8S_CONTEXT="$1"
}

lazy_k8s_namespace() {
  if [ $# -eq 0 ]; then
    printf '%s\n' "${K8S_NAMESPACE:-default}"
    return 0
  fi

  K8S_NAMESPACE="$1"
  printf '%s\n' "$K8S_NAMESPACE"
}

# ── public API ───────────────────────────────────────

lazy_register k8s kgp kgs kgd kga klog kex kctx kns

function kgp() {
  lazy_k8s_get pods "$@"
}

function kgs() {
  lazy_k8s_get svc "$@"
}

function kgd() {
  lazy_k8s_get deploy "$@"
}

function kga() {
  lazy_k8s_get all "$@"
}

function klog() {
  lazy_k8s_logs "$@"
}

function kex() {
  lazy_k8s_exec "$@"
}

function kctx() {
  lazy_k8s_context "$@"
}

function kns() {
  lazy_k8s_namespace "$@"
}
