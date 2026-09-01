#!/usr/bin/env bash
# modules/aws/aws.test.sh — full behavior coverage

# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_aws_full() {
  lazy_test_mock_reset

  lazy_test_mock_cmd aws '
printf "%s\n" "$*" >> "$LAZY_TEST_MOCK_DIR/log/aws"
exit 0
'

  unset AWS_PROFILE AWS_REGION AWS_DEFAULT_REGION 2>/dev/null || true
  export AWS_PROFILE_DEFAULT=default
  export AWS_REGION_DEFAULT=us-east-1

  lazy_test_assert_eq "aws:apro-default" "$(apro)" "$(lazy_aws_profile)"
  apro prod >/dev/null
  lazy_test_assert_eq "aws:apro-set" "$(apro)" "prod"

  lazy_test_assert_eq "aws:areg-default" "$(areg)" "$(lazy_aws_region)"
  areg eu-west-1 >/dev/null
  lazy_test_assert_eq "aws:areg-set" "$(areg)" "eu-west-1"

  awho >/dev/null 2>&1 || { lazy_test_line "aws:awho" fail "awho"; return; }
  lazy_test_assert_contains "aws:awho" "$(lazy_test_mock_last aws)" "sts get-caller-identity"

  awho staging >/dev/null 2>&1
  lazy_test_assert_contains "aws:awho-profile" "$(lazy_test_mock_last aws)" "--profile staging sts get-caller-identity"

  as3 >/dev/null 2>&1
  lazy_test_assert_contains "aws:as3" "$(lazy_test_mock_last aws)" "s3 ls"

  as3 my-bucket >/dev/null 2>&1
  lazy_test_assert_contains "aws:as3-bucket" "$(lazy_test_mock_last aws)" "s3 ls s3://my-bucket"

  aec2 >/dev/null 2>&1
  lazy_test_assert_contains "aws:aec2" "$(lazy_test_mock_last aws)" "ec2 describe-instances"

  alog /aws/lambda/foo >/dev/null 2>&1 || { lazy_test_line "aws:alog" fail "alog"; return; }
  lazy_test_assert_contains "aws:alog" "$(lazy_test_mock_last aws)" "logs tail /aws/lambda/foo --follow"

  lazy_test_assert_fail "aws:alog-missing" alog
}

lazy_test_aws_full
