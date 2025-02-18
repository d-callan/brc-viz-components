# The objective is to build a json object with the following structure:
# {
#   "chromosomes": [
#     1: {
#          "column1NodeIds": ["gene1", "gene2"],
#          "column2NodeIds": ["sample1", "sample2"],
#          "links": [
#              {
#                  "source": "gene1",
#                  "target": "sample1",
#                  "value": 4,
#                  "color": .76,
#                  "non-synonymous": 2,
#                  "stop_gained": 1,
#                  "start_lost": 1
#              },
#              {
#                  "source": "gene1",
#                  "target": "sample2",
#                  "value": 2,
#                  "color": .33,
#                  "non-synonymous": 1,
#                  "stop_gained": 1,
#                  "start_lost": 0
#              },
#              {
#                  "source": "gene2",
#                  "target": "sample1",
#                  "value": 1,
#                  "color": .5,
#                  "non-synonymous": 1,
#                  "stop_gained": 0,
#                  "start_lost": 0
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
# value is what well set stroke width by, is the count of all non-synonymous variants
# color is median allele frequency for all non-synonymous variants
# any fields in links other than source, target, and value can be shown in a tooltip

library(data.table)
library(jsonlite)

variants <- fread("variants_subset.tab", header = T, sep = "\t")
# header looks like this: Sample,CHROM,POS,FILTER,REF,ALT,DP,AF,DP4,SB,EFF[*].IMPACT,EFF[*].FUNCLASS,EFF[*].EFFECT,EFF[*].GENE,EFF[*].CODON,EFF[*].AA,EFF[*].TRID
names(variants) <- c("sample", "chromosome", "position", "filter", "ref", "alt", "dp", "af", "dp4", "sb", "impact", "funclass", "effect", "gene", "codon", "aa", "trid")

# arbitrary subset for now to make the data a workable size for testing
#variants <- head(variants, 1000)

buildJSON <- function(variants) {
    column1NodeIds <- sort(unique(variants$gene))
    column2NodeIds <- unique(variants$sample)
    links <- variants[, .(
        source = gene, 
        target = sample, 
        value = sum(!effect %in% c('SYNONYMOUS_CODING', '.', 'INTRAGENIC')), 
        color = median(af),
        stop_gained = sum(effect == 'STOP_GAINED'),
        start_lost = sum(effect == 'START_LOST'),
        non_synonymous = sum(effect == 'NON_SYNONYMOUS_CODING'),
        exon = sum(effect == 'EXON'),
        splice_site = sum(effect == 'SPLICE_SITE_REGION'),
        splice_site_synonymous = sum(effect == 'SPLICE_SITE_REGION+SYNONYMOUS_CODING'),
        splice_site_stop_lost = sum(effect == 'STOP_LOST+SPLICE_SITE_REGION'),
        splice_site_non_synonymous = sum(effect == 'NON_SYNONYMOUS_CODING+SPLICE_SITE_REGION'),
        splice_site_syn_stop = sum(effect == 'SPLICE_SITE_REGION+SYNONYMOUS_STOP')
        ), by = gene]
    links <- links[links$value > 0,]
    return(list(column1NodeIds = column1NodeIds, column2NodeIds = column2NodeIds, links = links))
}

json <- buildJSON(variants)

writeLines(toJSON(json, auto_unbox = T), "variants_by_gene.json")