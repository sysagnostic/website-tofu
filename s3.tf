resource "aws_s3_bucket" "website" {
  for_each = local.s3_bucket_names
  bucket = each.key
}

data "aws_iam_policy_document" "allow_cdn_origin_access" {
  for_each = local.s3_bucket_names
  statement {
    principals {
      type          = "Service"
      identifiers   = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.website[each.key].arn}/*",
    ]
    condition {
      test          = "ForAnyValue:StringEquals"
      variable      = "AWS:SourceArn"
      values        = [aws_cloudfront_distribution.website[each.key].arn]
    }
  }
  statement {
    principals {
      type          = "AWS"
      identifiers   = [local.github_actions_arn]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.website[each.key].arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_cdn_origin_access" {
  for_each          = local.s3_bucket_names
  bucket            = aws_s3_bucket.website[each.key].id
  policy            = data.aws_iam_policy_document.allow_cdn_origin_access[each.key].json
}
