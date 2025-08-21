nextflow.enable.dsl=2

params.input = null
params.container = null

if (!params.input)  exit 1, "Missing: --input s3://bucket/prefix/*.fastq.gz"
if (!params.container) exit 1, "Missing: --container <ecr-uri>"

process DUMMY_PROCESS {
  container params.container
  publishDir "/mnt/workflow/pubdir"   // required by HealthOmics

  cpus 1
  memory "1 GB"

  input:
  path input_file

  output:
  path "dummy_output.txt"

  script:
  """
  echo "Processed file: ${input_file}" > dummy_output.txt
  """
}

workflow {
  input_ch = Channel.fromPath(params.input)  // S3 URIs + globs supported
  DUMMY_PROCESS(input_ch)
}
