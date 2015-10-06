require! { d3, 'webtorrent': WebTorrent }

nodes = d3.range 100 .map -> radius: 10

root = nodes[0]
  ..x = 0.5 * window.inner-width
  ..y = 0.5 * window.inner-height
  ..radius = 20
  ..fixed = true

#nodes = d3.range 100 .map -> 

force = d3.layout.force!
  .size [window.inner-width, window.inner-height]
  .charge (d, i) -> if i then -50 else -1000
  .nodes nodes
  .start!


svg = d3.select \body
  .append \svg:svg
  .attr \width  window.inner-width
  .attr \height window.inner-height

svg.select-all \circle
  .data nodes
  .enter!.append \svg:circle
  .attr \r -> it.radius - 2
  .style \fill -> if it.fixed then \blue else \red


force.on \tick ->
  svg.select-all \circle
    .attr \cx -> it.x
    .attr \cy -> it.y

/*
client = new WebTorrent!
hash = \da40fb70e29f1fc659cd21848ff7d431ff48feb8

client.add hash, (torrent) !->
  torrent.files.for-each !->
    it.append-to \body
*/
