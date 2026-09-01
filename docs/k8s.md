# k8s (`k`)

prefix: **k** · needs: `kubectl`

| command | does |
|---------|------|
| `kgp` | `kubectl get pods` |
| `kgs` | `kubectl get svc` |
| `kgd` | `kubectl get deploy` |
| `kga` | `kubectl get all` |
| `klog mypod` | `kubectl logs -f mypod` |
| `kex mypod` | `kubectl exec -it mypod -- sh` |
| `kex mypod bash` | pick shell |
| `kctx` | print current context |
| `kctx minikube` | switch context (this shell) |
| `kns` | print current namespace |
| `kns kube-system` | switch namespace for later lazy k8s commands |

extra `kubectl` flags pass through (`kgp -o wide`, etc.).

**config:** `K8S_NAMESPACE`, `K8S_CONTEXT`.

`-n` / `--context` on a single command override config once. `kns` / `kctx` change the session.
