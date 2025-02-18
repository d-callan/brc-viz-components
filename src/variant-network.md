```js
import * as bpnet from "./bipartite-network.js";
```

# Variants as a Bipartite Network

This is me exploring whether a bipartite network is useful for visualizing variants.
I generally feel most things ive seen previously were kind of visually overwhelming and
not super helpful in identifying potential high-level patterns. Here we go..

## Columnar

position is first column, sample is second. edges colored by variant effect iirc.

```js
const pos_start = 1;
const pos_end = 10000;
```

```js
const variant_data = await FileAttachment("./data/variants.json").json();
// pass just first chromosome for now?
const first_chromosome = Object.keys(variant_data)[0];
// filter first_chromosome column1NodeIds by position inputs
const filteredColumn1NodeIds = variant_data[first_chromosome].column1NodeIds.filter(function (d) {
    return (d >= pos_start && d <= pos_end);
});
// filter links by pos_start and pos_end
const filteredLinks = variant_data[first_chromosome].links.filter(function (d) {
    return (d.source >= pos_start && d.source <= pos_end);
});
const filtered_variant_data = {
    column1NodeIds: filteredColumn1NodeIds,
    column2NodeIds: variant_data[first_chromosome].column2NodeIds,
    links: filteredLinks
}

const bpnet_svg = bpnet.render(filtered_variant_data, document.createElement("div"))
```

<div>${bpnet_svg}</div>