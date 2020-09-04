import math
import sys

replicates = 10

DATASET="spec-ops-aou.aou_arrays_40k"
SAMPLES_PER_TABLE=4000

print(f"INSERT INTO `{DATASET}.sample_list` (");
bits = []
for r in range(1,replicates):
    bits.append(f"SELECT sample_name || \"_T{r+1:02}\", {SAMPLES_PER_TABLE*r} + sample_id " \
          f"FROM `{DATASET}.sample_list` WHERE sample_id < 4000 \n ")

print(" UNION ALL\n ".join(bits))
print(");")


for r in range(1,replicates):
    print(f"CREATE OR REPLACE TABLE `{DATASET}.arrays_{r+1:03}` PARTITION BY RANGE_BUCKET(sample_id, GENERATE_ARRAY({SAMPLES_PER_TABLE*r}+1, {SAMPLES_PER_TABLE*(r+1)}, 1)) AS ")
    print(f"SELECT {SAMPLES_PER_TABLE*r} + sample_id as sample_id, probe_id, filter, GT_encoded, NORMX, NORMY, BAF, LRR " \
          f"FROM `{DATASET}.arrays_001`;\n ")