data "aws_iam_policy_document" "lambda_basic_policy" {
  statement {
    resources = ["arn:aws:logs:us-east-1:180294196620:*"]
    actions = ["logs:CreateLogGroup"]
    effect = "Allow"  
  }
  statement {
    resources = ["arn:aws:logs:us-east-1:180294196620:log-group:*:*"]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "lambda_basic_policy" {
  name              = "lambda_basic_policy"
  path              = "/service-role/"
  policy            = data.aws_iam_policy_document.lambda_basic_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
    effect = "Allow"
  }
}

resource "aws_iam_role" "hugo_url_rewrite_role" {
  name              = "hugoUrlRewriteRole"
  assume_role_policy= data.aws_iam_policy_document.assume_role_policy.json
  path              = "/service-role/"
}

resource "aws_iam_role_policy_attachments_exclusive" "lambda_basic_role_policy_attachment" {
  role_name         = aws_iam_role.hugo_url_rewrite_role.name
  policy_arns       = [aws_iam_policy.lambda_basic_policy.arn]
}


data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.mjs"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "hugo_url_rewrite" {
  provider          = aws.global
  function_name     = "hugoUrlRewrite"
  filename          = data.archive_file.lambda.output_path
  role              = aws_iam_role.hugo_url_rewrite_role.arn
  source_code_hash  = data.archive_file.lambda.output_base64sha256
  handler           = "index.handler"
  runtime           = "nodejs22.x"
  publish           = true
}
