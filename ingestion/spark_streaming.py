from pyspark.sql import SparkSession

KAFKA_BOOTSTRAP = "kafka:29092"
KAFKA_TOPIC = "crypto.prices"

spark = (
    SparkSession.builder
    .appName("crypto-streaming")
    .getOrCreate()
)
spark.sparkContext.setLogLevel("WARN")

df = (
    spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP)
    .option("subscribe", KAFKA_TOPIC)
    .option("startingOffsets", "earliest")
    .load()
)

parsed = df.selectExpr(
    "CAST(key AS STRING) AS symbol",
    "CAST(value AS STRING) AS json",
)

query = (
    parsed.writeStream
    .format("console")
    .option("truncate", "false")
    .outputMode("append")
    .start()
)

query.awaitTermination()
