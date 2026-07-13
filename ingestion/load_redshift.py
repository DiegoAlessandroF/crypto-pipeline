from pyspark.sql import SparkSession

S3_BUCKET = "crypto-pipeline-raw-492646067141"
DELTA_PATH = f"s3a://{S3_BUCKET}/raw/crypto_prices"
STAGING_PATH = f"s3a://{S3_BUCKET}/staging/crypto_prices"

spark = (
    SparkSession.builder
    .appName("crypto-load-redshift")
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
    .getOrCreate()
)
spark.sparkContext.setLogLevel("WARN")

# Leitura BATCH da tabela Delta.
# O Spark lê o _delta_log e resolve o snapshot atual, ignorando
# Parquet órfãos.
df = spark.read.format("delta").load(DELTA_PATH)

# Escreve o extrato limpo em Parquet no staging.
# coalesce(1): um único arquivo (volume baixo) — resolve o small-files.
# overwrite: substitui o staging a cada execução (idempotente).
(
    df.coalesce(1)
    .write
    .format("parquet")
    .mode("overwrite")
    .save(STAGING_PATH)
)

print(f"Extrato gravado em {STAGING_PATH}")
spark.stop()
