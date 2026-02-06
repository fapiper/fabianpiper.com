output "namespace" {
  value       = join("", oci_objectstorage_bucket.default[*].namespace)
  description = "The object storage namespace"
}
