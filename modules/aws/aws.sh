#!/usr/bin/env bash
# modules/aws/aws.sh — aws cli shortcuts
# prefix: a
# public: awho as3 aec2 alog apro areg
#
# usage:
#   awho                       sts get-caller-identity
#   awho prod                  same, --profile prod (once)
#   as3                        s3 ls
#   as3 my-bucket              s3 ls s3://my-bucket
#   aec2                       ec2 describe-instances (table)
#   alog /aws/lambda/foo       logs tail --follow
#   apro                       print current profile
#   apro prod                  export AWS_PROFILE for this shell
#   areg / areg us-west-2      same for region
#
# profile/region: session env (apro/areg) > config defaults.
# extra flags always pass through.

# ── internals ────────────────────────────────────────

lazy_aws_require() {
  if ! lazy_has aws; then
    lazy_error "aws cli is not installed"
    return 127
  fi
}

lazy_aws_profile() {
  printf '%s' "${AWS_PROFILE:-${AWS_PROFILE_DEFAULT:-default}}"
}

lazy_aws_region() {
  printf '%s' "${AWS_REGION:-${AWS_DEFAULT_REGION:-${AWS_REGION_DEFAULT:-us-east-1}}}"
}

# Insert --profile / --region unless the caller already passed them.
lazy_aws() {
  lazy_aws_require || return $?

  if ! lazy_has_flag --profile "$@"; then
    set -- --profile "$(lazy_aws_profile)" "$@"
  fi

  if ! lazy_has_flag --region "$@"; then
    set -- --region "$(lazy_aws_region)" "$@"
  fi

  command aws "$@"
}

lazy_aws_who() {
  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    lazy_aws --profile "$1" sts get-caller-identity
    return $?
  fi
  lazy_aws sts get-caller-identity "$@"
}

lazy_aws_s3_ls() {
  if [ $# -eq 0 ]; then
    lazy_aws s3 ls
    return $?
  fi

  if lazy_is_flag "$1"; then
    lazy_aws s3 ls "$@"
    return $?
  fi

  local target="$1"
  shift
  case "$target" in
    s3://*) ;;
    *) target="s3://${target}" ;;
  esac
  lazy_aws s3 ls "$target" "$@"
}

lazy_aws_ec2() {
  lazy_aws ec2 describe-instances \
    --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,Name:Tags[?Key==`Name`].Value|[0]}' \
    --output table \
    "$@"
}

lazy_aws_logs() {
  if [ $# -eq 0 ]; then
    lazy_error "alog <log-group>"
    return 2
  fi

  local group="$1"
  shift
  lazy_aws logs tail "$group" --follow "$@"
}

lazy_aws_set_profile() {
  if [ $# -eq 0 ]; then
    printf '%s\n' "$(lazy_aws_profile)"
    return 0
  fi
  export AWS_PROFILE="$1"
  printf '%s\n' "$AWS_PROFILE"
}

lazy_aws_set_region() {
  if [ $# -eq 0 ]; then
    printf '%s\n' "$(lazy_aws_region)"
    return 0
  fi
  export AWS_REGION="$1"
  export AWS_DEFAULT_REGION="$1"
  printf '%s\n' "$AWS_REGION"
}

# ── public API ───────────────────────────────────────

lazy_register aws awho as3 aec2 alog apro areg

function awho() {
  lazy_aws_who "$@"
}

function as3() {
  lazy_aws_s3_ls "$@"
}

function aec2() {
  lazy_aws_ec2 "$@"
}

function alog() {
  lazy_aws_logs "$@"
}

function apro() {
  lazy_aws_set_profile "$@"
}

function areg() {
  lazy_aws_set_region "$@"
}
