from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, to_timestamp
from pyspark.sql.types import StructType, StructField, StringType, LongType, BooleanType, DoubleType

KAFKA_BOOTSTRAP = "kafka:29092"
KAFKA_TOPIC = "crypto.prices"

S3_BUCKET = "crypto-pipeline-raw-492646067141"
DELTA_PATH = f"s3a://{S3_BUCKET}/raw/crypto_prices"
CHECKPOINT_PATH = f"s3a://{S3_BUCKET}/checkpoints/crypto_prices"

spark = (
    SparkSession.builder
    .appName("crypto-streaming")
    .getOrCreate()
)
spark.sparkContext.setLogLevel("WARN")


trade_schema = StructType([
    StructField("s", StringType()),   
    StructField("p", StringType()),   
    StructField("q", StringType()),   
    StructField("T", LongType()),     
    StructField("E", LongType()),     
    StructField("m", BooleanType()),  
])

raw = (
    spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP)
    .option("subscribe", KAFKA_TOPIC)
    .option("startingOffsets", "earliest")
    .load()
)

parsed = (
    raw
    .selectExpr("CAST(value AS STRING) AS json_str")
    .select(from_json(col("json_str"), trade_schema).alias("data"))
    .select(
        col("data.s").alias("symbol"),
        col("data.p").cast(DoubleType()).alias("price"),
        col("data.q").cast(DoubleType()).alias("quantity"),
        to_timestamp(col("data.T") / 1000).alias("trade_time"),
        to_timestamp(col("data.E") / 1000).alias("event_time"),
        col("data.m").alias("is_buyer_maker"),
    )
)

query = (
    parsed.writeStream
    .format("delta")
    .option("checkpointLocation", CHECKPOINT_PATH)
    .outputMode("append")
    .trigger(processingTime="30 seconds")
    .start(DELTA_PATH)
)

query.awaitTermination()
