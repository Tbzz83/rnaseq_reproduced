#
# Combine transcripts with the tximport package. 
# 
# https://bioconductor.org/packages/release/bioc/html/tximport.html
#
# Transcript level summarization.
#

# Load the packages
library(tximport)

# The directory where the counts for each sample are located.
data_dir <- 'salmon'

# The sample file must be in CSV format and must have the headers "sample" and "condition".
desing_file = "design.csv"

# What software created the mappings.
method <- "salmon"

# The output file name.
output_file = "counts.csv"

# Inform the user.
print("# Tool: Combine transcripts")
print(paste("# Sample: ", desing_file))
print(paste("# Data dir: ", data_dir))

# Read the sample file
sample_data <- read.csv(desing_file, stringsAsFactors=F)

# Isolate the sample names.
sample_names <- sample_data$sample

# Generate the file names that contain the quantification data.
files <- file.path(data_dir,  sample_names, "quant.sf")

# Summarize over transcripts.
tx <- tximport(files, type=method, txOut=TRUE)

# Transform counts into a dataframe.
df <- data.frame(tx$counts)

# Set the column names.
colnames(df) <- sample_names

# Create a new column for transcript ids.
df$ensembl_transcript_id = rownames(df)

# List the desired column order.
cols <- c("ensembl_transcript_id", sample_names)
  
# Reorganize the columns.
df <- df[, cols]

# Save the  resulting summarized counts.
write.csv(df, file=output_file,  row.names = FALSE, quote = FALSE)

# Inform the user.
print(paste("# Results: ", output_file))
