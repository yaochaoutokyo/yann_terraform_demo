output "name" {
    value = var.create == true ? aws_codebuild_project.codebuild[0].name : ""
}