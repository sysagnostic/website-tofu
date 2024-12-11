resource "aws_acm_certificate" "public_cert" {
  provider = aws.global
  domain_name               = "sysagnostic.com"
  subject_alternative_names = [
    "*.sysagnostic.com"
  ]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"
}

resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "CloudFront access identity for S3"
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
    origin_access_control_id = "EBMK8TUX648H5"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.public_cert.arn
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
    lambda_function_association {
      event_type   = "origin-request"
      include_body = false
      lambda_arn   = aws_lambda_function.hugo_url_rewrite.qualified_arn
    }
  }
}
