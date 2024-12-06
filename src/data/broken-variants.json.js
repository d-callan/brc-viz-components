// The objective is to build a json object with the following structure:
// {
//   "chromosomes": [
//     1: {
//          "column1NodeIds": ["locus1", "locus2"],
//          "column2NodeIds": ["sample1", "sample2"],
//          "links": [
//              {
//                  "source": "locus1",
//                  "target": "sample1",
//                  "value": "synonymous",
//                  "ref": "A",
//                  "alt": "G",
//                  "gene": "gene1"
//                  "other_field": "value"
//              },
//              {
//                  "source": "locus1",
//                  "target": "sample2",
//                  "value": "non-synonymous",
//                  "ref": "A",
//                  "alt": "G"
//              },
//              {
//                  "source": "locus2",
//                  "target": "sample1",
//                  "value": "synonymous",
//                  "ref": "A",
//                  "alt": "G"
//              }
//          ]
//      },
//     2: {
//          "column1NodeIds": [],
//          "column2NodeIds": [],
//          "links": []
//      }
//   ]
// }
// value is what well color by, should be categorical w less than 10 colors.
// any fields in links other than source, target, and value can be shown in a tooltip

const reader = new FileReader(); 

//const text = await fetch("https://usegalaxy.org/api/datasets/f9cad7b01a472135d0cbdeeffd6c9a1e/display?to_ext=tabular").then(response => response.text());
// header looks like this: Sample,CHROM,POS,FILTER,REF,ALT,DP,AF,DP4,SB,EFF[*].IMPACT,EFF[*].FUNCLASS,EFF[*].EFFECT,EFF[*].GENE,EFF[*].CODON,EFF[*].AA,EFF[*].TRID
const text = await reader.readAsText("variants_subset.tab");
console.log(text);
const rows = text.trim().split('\n').slice(1); // first line is header
const data = {
    chromosomes: {}
};
console.log(rows.length);
rows.forEach(row => {
    const columns = row.split('\t');
    const sample = columns[0];
    const chromosome = parseInt(columns[1], 10);
    const locus = `locus${columns[2]}`;
    const ref = columns[4];
    const alt = columns[5];
    const effect = columns[12];
    const gene = columns[13];

    if (!data.chromosomes[chromosome]) {
        data.chromosomes[chromosome] = {
            column1NodeIds: [],
            column2NodeIds: [],
            links: []
        };
    }

    const chromosomeData = data.chromosomes[chromosome];

    if (!chromosomeData.column1NodeIds.includes(locus)) {
        chromosomeData.column1NodeIds.push(locus);
    }

    if (!chromosomeData.column2NodeIds.includes(sample)) {
        chromosomeData.column2NodeIds.push(sample);
    }

    chromosomeData.links.push({
        source: locus,
        target: sample,
        value: effect,
        ref: ref,
        alt: alt,
        gene: gene
    });
});

// for each chromosome, add to column1NodeIds any locus that isnt already there

Object.values(data.chromosomes).forEach(chromosomeData => {
    chromosomeData.column1NodeIds = chromosomeData.column1NodeIds.sort();
    
    // find max locus number
    const maxLocusNumber = Math.max(...chromosomeData.column1NodeIds.map(locus => parseInt(locus.replace('locus', ''), 10)));
    // add any missing loci
    for (let i = 1; i <= maxLocusNumber; i++) {
        if (!chromosomeData.column1NodeIds.includes(`locus${i}`)) {
            chromosomeData.column1NodeIds.push(`locus${i}`);
        }
    }
    chromosomeData.column1NodeIds = chromosomeData.column1NodeIds.sort();
});

process.stdout.write(JSON.stringify(data));
