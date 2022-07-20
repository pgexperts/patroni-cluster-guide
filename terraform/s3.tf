resource "aws_s3_bucket" "files" {
  bucket_prefix = "etcd3-files"
}

resource "aws_s3_bucket_acl" "files_acl" {
  bucket = aws_s3_bucket.files.id
  acl    = "private"
}

resource "aws_s3_object" "etcd3-bootstrap-linux-amd64" {
  bucket       = aws_s3_bucket.files.id
  key          = "etcd3-bootstrap-linux-amd64"
  source       = "files/etcd3-bootstrap-linux-amd64"
  etag         = filemd5("files/etcd3-bootstrap-linux-amd64")
  acl          = "public-read"
  content_type = "application/octet-stream"
}

resource "aws_s3_object" "certificate-bootstrap" {
  bucket = aws_s3_bucket.files.id
  key    = "certificate-bootstrap.sh"
  content = templatefile("${path.module}/templates/certificate-bootstrap.sh", {
    ssl_cert_dir      = var.ssl_cert_dir
    ca_cert_pem       = "s3://${aws_s3_bucket.files.bucket}/${aws_s3_object.etcd-ca-cert.id}"
    key_pem           = "s3://${aws_s3_bucket.files.bucket}/${aws_s3_object.etcd-tls-key.id}"
    cert_pem          = "s3://${aws_s3_bucket.files.bucket}/${aws_s3_object.etcd-tls-cert.id}"
    etcd_ca_cert_path = var.etcd_ca_cert_path
    etcd_key_path     = var.etcd_key_path
    etcd_cert_path    = var.etcd_cert_path
    etcd_cert_owner   = var.etcd_cert_owner
    }
  )
  content_type = "text/plain"
}

resource "aws_s3_object" "etcd-ca-cert" {
  bucket       = aws_s3_bucket.files.id
  key          = "etcd-ca-cert.pem"
  content      = tls_self_signed_cert.ca.cert_pem
  content_type = "text/plain"
}

resource "aws_s3_object" "etcd-tls-key" {
  bucket       = aws_s3_bucket.files.id
  key          = "key.pem"
  content      = tls_private_key.etcd.private_key_pem
  content_type = "text/plain"
}

resource "aws_s3_object" "etcd-tls-cert" {
  bucket       = aws_s3_bucket.files.id
  key          = "cert.pem"
  content      = tls_locally_signed_cert.etcd.cert_pem
  content_type = "text/plain"
}
