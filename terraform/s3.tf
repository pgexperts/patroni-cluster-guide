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
