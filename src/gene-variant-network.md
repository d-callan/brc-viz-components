```js
import * as forcenet from "./force-bp-net.js";
```

# Variants by Gene Network

This is me exploring whether a bipartite network is useful for visualizing variants.
I generally feel most things ive seen previously were kind of visually overwhelming and
not super helpful in identifying potential high-level patterns. Here we go..

## Force directed

This is similar data to columnar but summarized to genes, by finding the total number of
all variants for each effect class across all bases within a gene. here,edges have stroke 
width set to median allele frequency across all variants within the gene for that particular 
sample. The idea is that you would first select an 'effect' type of interest, and get a histogram
showing the median number of variants within a gene matching that selected effect. This
histogram can be interacted with to filter the network to, for example, only include genes
with a large or small number of variants matching the effect category.

<br>

```js
const variant_data = await FileAttachment("./data/variants_by_gene.json").json();

const linkProps = Object.keys(variant_data.links[0]).filter(prop => !["value", "color", "gene", "source", "target"].includes(prop));
```

<hr>

```js
const selected_effect = view(Inputs.select(linkProps, {label: html`<b>Effect category of interest: </b>`}));
```

```js
const filteredLinks = variant_data.links.filter(function (d) {
    return d[selected_effect] > 0;
});

const filteredGenes = variant_data.column1NodeIds.filter(function (geneId) {
    return filteredLinks.some(function (link) {
        return link.source === geneId
    })
})

const filteredSamples = variant_data.column2NodeIds.filter(function (sampleId) {
    return filteredLinks.some(function (link) {
        return link.target === sampleId;
    });
});

const filtered_variant_data = {
    column1NodeIds: filteredGenes,
    column2NodeIds: filteredSamples,
    links: filteredLinks
};
```

```js
const startEnd = Mutable(null);
const setStartEnd = (se) => startEnd.value = se;

const gene_summaries = filteredGenes.map(geneId => {
    const matching_links = filteredLinks.filter(link => link.source === geneId);
    const median_value = d3.median(matching_links, link => link[selected_effect]);
    return {
        gene: geneId,
        median_value
    }
});

const effect_hist = Plot.plot({
      title: "Distribution of the median number of matching variants per gene",
      subtitle: "Selecting regions of the histogram produces a network diagram filtered by matching genes",
      width,
      height: 300,
      y: {
        label: "count (genes)",
        grid: true
      },
      marks: [
        Plot.axisX({ label: "median number variants per gene across samples" }),
        Plot.rectY(
          gene_summaries,
          Plot.binX(
            { y: "count" },
            { x: "median_value", fill: 'steelblue' }
          )
        ),
        Plot.ruleY([0]),
        (index, scales, channels, dimensions, context) => {
            const x1 = dimensions.marginLeft;
            const x2 = dimensions.width - dimensions.marginRight;
            const y1 = 0;
            const y2 = dimensions.height;
            const brushed = (event) => setStartEnd(event.selection?.map(scales.x.invert));
            const brush = d3.brushX().extent([[x1, y1], [x2, y2]]).on("brush end", brushed);
            return d3.create("svg:g").call(brush).node();
        }
      ]
    })
```

<div>${effect_hist}</div>

```js
const brushed_gene_candidates = () => {
    const brushed_genes = gene_summaries.filter(gene_summary => {
        return gene_summary.median_value > startEnd[0] && gene_summary.median_value < startEnd[1];
    }).map(gene_summary => gene_summary.gene);
    return brushed_genes;
}
console.log(brushed_gene_candidates())
const getBrushedLinks = () => {
    const brushed_genes = brushed_gene_candidates();
    return filteredLinks.filter(function (d) {
        return brushed_genes.includes(d.source);
    }).map(function (d) {
        return Object.assign({}, d, { value: d.color });
    });
}
const brushedLinks = getBrushedLinks();

const brushedGenes = filteredGenes.filter(function (geneId) {
    return brushedLinks.some(function (link) {
        return link.source === geneId
    })
})

const brushedSamples = filteredSamples.filter(function (sampleId) {
    return brushedLinks.some(function (link) {
        return link.target === sampleId;
    });
});

const brushed_variant_data = {
    column1NodeIds: brushedGenes,
    column2NodeIds: brushedSamples,
    links: brushedLinks
};
```

```js
const force_net = forcenet.render(brushed_variant_data, document.createElement("div"));
```

<div>${force_net}</div>

## Follow-up Thoughts

This could probably be pretty significantly improved by incorporating sample metadata,
context about genes.

Ideally, once a gene of potential interest was identified wed show more detailed info,
maybe even the little heatmap-style browser of Anton's.

Pros:
1. presenting summary info means we pass less data to the browser, which is a big deal
considering theres GBs of data..
2. helps ppl find genes, which is probably the unit they most care about most of
the time
3. highlights that some genes see a lot of variation, and others not, and lets ppl
filter by this
4. the network being force directed makes it easy to see when genes follow very different 
patterns of variation across samples

Cons:
1. obviously presenting data this summarized/ aggregated makes it harder for ppl to know
what theyre looking at, increases our burden to explain
2. showing more than a handful of genes + samples gets messy pretty quickly. there are 
some combinations where i dont have a good way to filter/ avoid this yet (small # non-syn)
3. probably other things, but im horribly biased in my own favor lol