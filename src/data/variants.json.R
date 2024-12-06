# The objective is to build a json object with the following structure:
# {
#   "chromosomes": [
#     1: {
#          "column1NodeIds": ["locus1", "locus2"],
#          "column2NodeIds": ["sample1", "sample2"],
#          "links": [
#              {
#                  "source": "locus1",
#                  "target": "sample1",
#                  "value": "synonymous",
#                  "ref": "A",
#                  "alt": "G",
#                  "gene": "gene1"
#                  "other_field": "value"
#              },
#              {
#                  "source": "locus1",
#                  "target": "sample2",
#                  "value": "non-synonymous",
#                  "ref": "A",
#                  "alt": "G"
#              },
#              {
#                  "source": "locus2",
#                  "target": "sample1",
#                  "value": "synonymous",
#                  "ref": "A",
#                  "alt": "G"
#              }
#          ]
#      },
#     2: {
#          "column1NodeIds": [],
#          "column2NodeIds": [],
#          "links": []
#      }
#   ]
# }
# value is what well color by, should be categorical w less than 10 colors.
# any fields in links other than source, target, and value can be shown in a tooltip

library(data.table)
library(jsonlite)

variants <- fread("variants_subset.tab", header = T, sep = "\t")
# header looks like this: Sample,CHROM,POS,FILTER,REF,ALT,DP,AF,DP4,SB,EFF[*].IMPACT,EFF[*].FUNCLASS,EFF[*].EFFECT,EFF[*].GENE,EFF[*].CODON,EFF[*].AA,EFF[*].TRID
names(variants) <- c("sample", "chromosome", "position", "filter", "ref", "alt", "dp", "af", "dp4", "sb", "impact", "funclass", "effect", "gene", "codon", "aa", "trid")

# arbitrary subset for now to make the data a workable size for testing
#variants <- head(variants, 1000)

buildChromosomeJSON <- function(chromosome) {
    # Build the JSON object for the given chromosome
    column1NodeIds <- sort(unique(variants[chromosome == chromosome, position]))
    column2NodeIds <- unique(variants[chromosome == chromosome, sample])
    links <- variants[chromosome == chromosome, .(source = position, target = sample, value = funclass, ref = ref, alt = alt, gene = gene)]
    return(list(column1NodeIds = column1NodeIds, column2NodeIds = column2NodeIds, links = links))
}

chromosomes <- unique(variants$chromosome)
chromosomesJSON <- lapply(chromosomes, buildChromosomeJSON)
chromosomesJSON <- setNames(chromosomesJSON, chromosomes)

writeLines(toJSON(chromosomesJSON, auto_unbox = T), "variants.json")