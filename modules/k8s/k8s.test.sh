#!/usr/bin/env bash
# modules/k8s/k8s.test.sh — full behavior coverage

# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_k8s_full() {
  lazy_test_mock_reset

  lazy_test_mock_cmd kubectl '
printf "%s\n" "$*" >> "$LAZY_TEST_MOCK_DIR/log/kubectl"
exit 0
'

  export K8S_NAMESPACE=default
  export K8S_CONTEXT=""

  lazy_test_assert_eq "k8s:kns-default" "$(kns)" "default"

  kns staging >/dev/null
  lazy_test_assert_eq "k8s:kns-set" "$(kns)" "staging"

  kgp -o wide >/dev/null 2>&1 || { lazy_test_line "k8s:kgp" fail "kgp"; return; }
  lazy_test_assert_contains "k8s:kgp-ns" "$(lazy_test_mock_last kubectl)" "--namespace staging get pods -o wide"

  kgs >/dev/null 2>&1
  lazy_test_assert_contains "k8s:kgs" "$(lazy_test_mock_last kubectl)" "get svc"

  kgd >/dev/null 2>&1
  lazy_test_assert_contains "k8s:kgd" "$(lazy_test_mock_last kubectl)" "get deploy"

  kga >/dev/null 2>&1
  lazy_test_assert_contains "k8s:kga" "$(lazy_test_mock_last kubectl)" "get all"

  klog mypod >/dev/null 2>&1 || { lazy_test_line "k8s:klog" fail "klog"; return; }
  lazy_test_assert_contains "k8s:klog" "$(lazy_test_mock_last kubectl)" "logs -f mypod"

  kex mypod bash >/dev/null 2>&1 || { lazy_test_line "k8s:kex" fail "kex"; return; }
  lazy_test_assert_contains "k8s:kex" "$(lazy_test_mock_last kubectl)" "exec -it mypod -- bash"

  lazy_test_assert_fail "k8s:klog-missing" klog
  lazy_test_assert_fail "k8s:kex-missing" kex

  # context switch
  lazy_test_mock_cmd kubectl '
printf "%s\n" "$*" >> "$LAZY_TEST_MOCK_DIR/log/kubectl"
case "$*" in
  *config\ use-context*) exit 0 ;;
  *current-context*) printf "minikube\n"; exit 0 ;;
esac
exit 0
'
  kctx minikube >/dev/null 2>&1 || { lazy_test_line "k8s:kctx-set" fail "kctx set"; return; }
  lazy_test_assert_contains "k8s:kctx-set" "$(lazy_test_mock_last kubectl)" "config use-context minikube"

  kctx >/dev/null 2>&1
  lazy_test_assert_eq "k8s:kctx-get" "$(kctx)" "minikube"
}

lazy_test_k8s_full
