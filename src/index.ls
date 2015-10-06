require! { d3, 'webtorrent': WebTorrent }

width  = window.inner-width
height = window.inner-height

window.add-event-listener \resize onresize = !->
  width  := window.inner-width
  height := window.inner-height
  svg
    .attr \width  width
    .attr \height height
  force.size [ width, height ]
  force.start!

nodes = [{}]
links = []

root = nodes[0]
  ..x = 0.5 * width
  ..y = 0.5 * height
  ..radius = 100px

svg = d3.select \body
  .style \margin  0
  .style \padding 0
  .append \svg:svg

svg.select-all \circle
  .data nodes
  .enter!.insert \svg:circle
  .style \fill \blue
  .attr \r 0
  .transition!
  .duration 1000
  .ease \elastic
  .attr \r -> it.radius - 2

force = d3.layout.force!
  .charge (d, i) -> if i then -500 else -10000
  .link-strength 0.1
  .nodes nodes
  .links links

window.add-peer = add-peer = ->
  it
    ..x = Math.random! * 0.5 * width  + 0.25 * width
    ..y = Math.random! * 0.5 * height + 0.25 * height
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
    .style \fill \red
    .attr \r 0
      .transition!
        .duration 1000
        .ease \elastic
        .attr \r -> it.radius - 2

  force.start!

onresize!
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
