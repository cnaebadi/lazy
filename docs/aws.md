# aws (`a`)

prefix: **a** · needs: `aws` cli

| command | does |
|---------|------|
| `awho` | `aws sts get-caller-identity` |
| `awho prod` | same with `--profile prod` (once) |
| `as3` | `aws s3 ls` |
| `as3 my-bucket` | `aws s3 ls s3://my-bucket` |
| `aec2` | `aws ec2 describe-instances` (table output) |
| `alog /aws/lambda/foo` | `aws logs tail --follow` |
| `apro` | print current profile |
| `apro prod` | set `AWS_PROFILE` for this shell |
| `areg` | print current region |
| `areg us-west-2` | set `AWS_DEFAULT_REGION` for this shell |

extra flags pass through.

**config:** `AWS_PROFILE_DEFAULT`, `AWS_REGION_DEFAULT`.

session env (`apro` / `areg`) wins over config defaults.
