locals {
  raw_user_data  = jsondecode(file("${path.module}/iam_data/users.json"))
  raw_group_data = jsondecode(file("${path.module}/iam_data/groups.json"))
  user_data      = [for user in local.raw_user_data : user]
  group_data     = [for group in local.raw_group_data : group]

  usernames  = [for user in local.raw_user_data : user.username]
  groupnames = [for group in local.raw_group_data : group.name]

  group_policies = flatten([
    for group in local.group_data : [
      for policy_arn in group.policy_arns : {
        groupname  = group.name
        policy_arn = policy_arn
        id         = format("%s%s", group.name, policy_arn)
      }
    ]
  ])
}

output "group_data" {
  value = local.group_data
}

output "user_data" {
  value = local.user_data
}

output "group_policies" {
  value = local.group_policies
}

resource "aws_iam_user" "aws_terraform_guide" {
  for_each = toset(local.usernames)
  name     = each.value
}

resource "aws_iam_group" "aws_terraform_guide" {
  for_each = toset(local.groupnames)
  name     = each.value
}

resource "aws_iam_user_group_membership" "aws_terraform_guide" {
  for_each = { for user in local.user_data : user.username => user }
  user     = each.key

  groups = each.value.groups

  depends_on = [
    aws_iam_user.aws_terraform_guide
  ]
}

resource "aws_iam_group_policy_attachment" "aws_terraform_guide" {
  for_each = { for group in local.group_policies : group.id => group }

  group      = each.value.groupname
  policy_arn = each.value.policy_arn

  depends_on = [
    aws_iam_user_group_membership.aws_terraform_guide
  ]
}
