require! { d3, 'webtorrent': WebTorrent, 'node-uuid': uuid }

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

refresh = !->
  svg.select-all \line .data links
    ..exit!
      .transition!.remove!
        .duration 500ms
        .style \stroke-width 0px
    ..enter!.insert \svg:line \circle
      .style \stroke \grey
      .style \stroke-width 0px
      .transition!
        .duration 100ms
        .style \stroke-width 10px

  svg.select-all \circle .data nodes
    ..exit!
      .transition!.remove!
        .duration 1000ms
        .attr \r 0px
    ..enter!.insert \svg:circle
      .style \fill \red
      .attr \r 0px
        .transition!
          .duration 1000
          .ease \elastic
          .attr \r -> it.radius - 2px

  force.start!

window.add-peer = add-peer = !->
  it
    ..x = Math.random! * 0.5 * width  + 0.25 * width
    ..y = Math.random! * 0.5 * height + 0.25 * height
    ..radius = 50px

  nodes.push it
  links.push source: root, target: it

  refresh!

window.remove-peer = remove-peer = !->
  return unless ~(i = nodes.index-of it)
  nodes.splice i, 1
  for link, i in links
    if link.target is it
      links.splice i, 1

  refresh!

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

client = new WebTorrent!
hash = \951877bb4136451d079bde655ebbadc36190721e

client.add hash, (torrent) !->
  for wire of torrent.swarm.wires
    peer = id: uuid.v4!, ip: wire.remote-address
    wire.peer = peer
    add-peer peer
  torrent.on \wire (wire, addr) !->
    peer = id: uuid.v4!, ip: addr
    wire.peer = peer
    add-peer peer
    wire.once \close !->
      remove-peer wire.peer

  #torrent.files.for-each !->
  #  it.append-to \body
