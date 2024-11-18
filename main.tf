terraform {
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  root_domain = "sysagnostic.com"
  s3_bucket_names = toset(concat(["www.${local.root_domain}"], [for id in range(1, 4): format("www%d.%s", id, local.root_domain)]))
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
}
provider "aws" {
  alias = "global"
  region = "us-east-1"
}

resource "aws_acm_certificate" "public_cert" {
  provider = aws.global
  domain_name               = "sysagnostic.com"
  subject_alternative_names = [
    "*.sysagnostic.com"
  ]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"
}

resource "aws_s3_bucket" "website" {
  for_each = local.s3_bucket_names
  bucket = each.key
}

resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "CloudFront access identity for S3"
}

resource "aws_s3_bucket_policy" "allow_cdn_origin_access" {
  for_each = local.s3_bucket_names
  bucket = aws_s3_bucket.website["${each.key}"].id
  policy = data.aws_iam_policy_document.allow_cdn_origin_access[each.key].json
}

data "aws_iam_policy_document" "allow_cdn_origin_access" {
  for_each = local.s3_bucket_names
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.website.iam_arn]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.website[each.key].arn}/*",
    ]
  }
}

resource "aws_cloudfront_distribution" "website" {
  for_each = local.s3_bucket_names
  enabled = true
  default_root_object = "index.html"
  is_ipv6_enabled = true
  price_class = "PriceClass_100"
  aliases = each.key == "www.sysagnostic.com" ? ["sysagnostic.com", each.key] : [each.key]
  origin {
    domain_name = format("%s.s3.eu-north-1.amazonaws.com", each.key)
    origin_id = format("%s.s3.eu-north-1.amazonaws.com", each.key)
    connection_attempts = 3
    connection_timeout = 10
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:180294196620:certificate/75718dc4-eb94-412c-8d93-cc8c33838c7e"
    cloudfront_default_certificate = false
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
  default_cache_behavior {
    target_origin_id = format("%s.s3.eu-north-1.amazonaws.com", each.key)
    allowed_methods  = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cached_methods = ["GET", "HEAD"]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress = true
  }
}
