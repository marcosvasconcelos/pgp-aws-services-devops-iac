resource "aws_codepipeline" "pdftotxt" {
  name     = "${local.name_prefix}-pdftotxt-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.pdftotxt.name
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-pdftotxt-pipeline" })
}

resource "aws_codepipeline" "search_gateway" {
  name     = "${local.name_prefix}-search-gateway-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.search_gateway.name
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-search-gateway-pipeline" })
}

resource "aws_codepipeline" "search_function" {
  name     = "${local.name_prefix}-search-function-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.search_function.name
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-search-function-pipeline" })
}

resource "aws_codepipeline" "upload_to_search" {
  name     = "${local.name_prefix}-upload-to-search-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.upload_to_search.name
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-upload-to-search-pipeline" })
}

output "codepipeline_urls" {
  description = "URLs for CodePipeline consoles"
  value = {
    pdftotxt         = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.pdftotxt.name}/view"
    search_gateway   = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.search_gateway.name}/view"
    search_function  = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.search_function.name}/view"
    upload_to_search = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.upload_to_search.name}/view"
  }
}
