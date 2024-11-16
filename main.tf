terraform {
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "~> 5.0"
    }
  }
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

resource "aws_s3_bucket" "website_subdomain" {
  bucket = "www.sysagnostic.com"
}

resource "aws_s3_bucket" "website_root" {
  bucket = "sysagnostic.com"
}

resource "aws_s3_bucket_website_configuration" "root_redirect" {
  bucket = "sysagnostic.com"
  redirect_all_requests_to {
    host_name = "www.sysagnostic.com"
    protocol = "https"
  }
}

resource "aws_cloudfront_distribution" "website_subdomain_cdn" {
  # id = "EGZ5NHN8QDTN0"
  enabled = true
  default_root_object = "index.html"
  is_ipv6_enabled = true
  price_class = "PriceClass_100"
  aliases = [
    "www.sysagnostic.com"
  ]
  origin {
    domain_name = "www.sysagnostic.com.s3.eu-north-1.amazonaws.com"
    origin_id = "www.sysagnostic.com.s3.eu-north-1.amazonaws.com"
    connection_attempts = 3
    connection_timeout = 10
    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E1ES7836TJBHK1"
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
    target_origin_id = "www.sysagnostic.com.s3.eu-north-1.amazonaws.com"
    allowed_methods  = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cached_methods = ["GET", "HEAD"]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress = true
  }
}

resource "aws_cloudfront_distribution" "website_root_cdn" {
  # id = "EGZ5NHN8QDTN0"
  enabled = true
  is_ipv6_enabled = true
  price_class = "PriceClass_100"
  aliases = [
    "sysagnostic.com"
  ]
  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = "sysagnostic.com.s3-website.eu-north-1.amazonaws.com"
    origin_id           = "sysagnostic.com.s3-website.eu-north-1.amazonaws.com"
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = [
          "SSLv3",
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2",
      ]
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
    target_origin_id = "sysagnostic.com.s3-website.eu-north-1.amazonaws.com"
    allowed_methods  = ["GET", "HEAD"]
    viewer_protocol_policy = "allow-all"
    cached_methods = ["GET", "HEAD"]
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    compress = true
  }
}
