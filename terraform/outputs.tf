output "instance_public_ip" {
  description = "IP publico fixo (Elastic IP) da instancia EC2"
  value       = aws_eip.crypto_pipeline.public_ip
}

output "instance_id" {
  description = "ID da instancia EC2"
  value       = aws_instance.crypto_pipeline.id
}

output "ssh_command" {
  description = "Comando pronto para conectar via SSH na instancia"
  value       = "ssh -i ~/.ssh/crypto-pipeline-key ubuntu@${aws_eip.crypto_pipeline.public_ip}"
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 de dados brutos"
  value       = aws_s3_bucket.raw_data.bucket
}
