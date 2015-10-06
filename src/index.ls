require! { querystring, d3, 'webtorrent': WebTorrent, 'node-uuid': uuid }

const NODE_RADIUS = 64px

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
  .style \background-color \#030c22

load-flag = (ip) !->
  svg.append \defs
    .append \pattern
      ..
        .attr \id ip
        .attr \width  64
        .attr \height 64
      ..append \svg:rect
        .attr \width  2 * NODE_RADIUS
        .attr \height 2 * NODE_RADIUS
        .style \fill \#20293f
      ..append \svg:image
        .attr \width  2 * NODE_RADIUS
        .attr \height 2 * NODE_RADIUS
        .attr \xlink:href "flag?ip=#ip"

svg.select-all \.node
  .data nodes
    .enter!.insert \svg:circle
    .attr \class \node
    .attr \r 0
    .style \fill \#e0d498
    .transition!
      .duration 1000
      .ease \elastic
      .attr \r -> it.radius

force = d3.layout.force!
  .charge (d, i) -> if i then -500 else -10000
  .link-strength 0.1
  .nodes nodes
  .links links

refresh = !->
  svg.select-all \.link .data links
    ..exit!
      .transition!.remove!
        .duration 500ms
        .style \stroke-width 0px
    ..enter!.insert \svg:line \.node
      .attr \class \link
      .style \stroke \#e5e7e8
      .style \stroke-width 0px
      .transition!
        .duration 100ms
        .style \stroke-width 10px

  svg.select-all \.node .data nodes
    ..exit!
      .transition!.remove!
        .duration 1000ms
        .attr \r 0px
    ..enter!.insert \svg:circle
      .attr \class \node
      .style \fill -> "url(##{it.ip})"
      .attr \r 0px
        .transition!
          .duration 1000
          .ease \elastic
          .attr \r -> it.radius

  force.start!

window.add-peer = add-peer = !->
  load-flag it.ip

  it
    ..x = Math.random! * 0.5 * width  + 0.25 * width
    ..y = Math.random! * 0.5 * height + 0.25 * height
    ..radius = NODE_RADIUS
    ..ip = it.ip

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
  svg.select-all \.link
    .attr \x1 -> it.source.x
    .attr \y1 -> it.source.y
    .attr \x2 -> it.target.x
    .attr \y2 -> it.target.y

  svg.select-all \.node
    .attr \cx -> it.x
    .attr \cy -> it.y

client = new WebTorrent!
hash = \951877bb4136451d079bde655ebbadc36190721e

client.add hash, (torrent) !->
  for wire in torrent.swarm.wires
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


export get = (url, data, callback) !->
  xhr = new XMLHttpRequest!
  xhr.onload = !-> callback @response
  xhr.open \GET url + '?' + querystring.stringify data
  xhr.send!
