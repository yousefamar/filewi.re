require! { d3, 'webtorrent': WebTorrent }

nodes = [{}]
links = []

root = nodes[0]
  ..x = 0.5 * window.inner-width
  ..y = 0.5 * window.inner-height
  ..radius = 100px
  ..fixed = true

svg = d3.select \body
  .style \margin  0
  .style \padding 0
  .append \svg:svg
  .attr \width  window.inner-width
  .attr \height window.inner-height

svg.select-all \circle
  .data nodes
  .enter!.insert \svg:circle
  .attr \r -> it.radius - 2
  .style \fill \blue

force = d3.layout.force!
  .size [window.inner-width, window.inner-height]
  .charge (d, i) -> if i then -500 else -10000
  .link-strength 0.1
  .nodes nodes
  .links links

window.add-peer = add-peer = ->
  it
    ..x = Math.random! * 0.5 * window.inner-width  + 0.25 * window.inner-width
    ..y = Math.random! * 0.5 * window.inner-height + 0.25 * window.inner-height
    ..radius = 50px

  nodes.push it
  links.push source: root, target: it

  svg.select-all \line
    .data links
    .enter!.insert \svg:line \circle
    .style \stroke-width -> 10px
    .style \stroke -> \grey

  svg.select-all \circle
    .data nodes
    .enter!.insert \svg:circle
    .attr \r -> it.radius - 2
    .style \fill \red

  force.start!

force.start!

force.on \tick ->
  svg.select-all \line
    .attr \x1 -> it.source.x
    .attr \y1 -> it.source.y
    .attr \x2 -> it.target.x
    .attr \y2 -> it.target.y

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
