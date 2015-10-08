require! { querystring, d3, 'webtorrent': WebTorrent, dropzone: Dropzone, 'node-uuid': uuid, jade }

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
  ..progress-angle = 0

svg = d3.select \body
  .style \margin  0
  .style \padding 0
  .style \width   \100%
  .style \height  \100%
  .style \overflow \hidden
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
        .attr \width  2.5 * NODE_RADIUS
        .attr \height 2.5 * NODE_RADIUS
        .style \fill \#20293f
      ..append \svg:image
        .attr \width  2 * NODE_RADIUS
        .attr \height 2 * NODE_RADIUS
        .attr \xlink:href "flag?ip=#ip"


arc = d3.svg.arc!
  .inner-radius 95px
  .outer-radius 110px
  .start-angle  0rad

svg.select-all \.node
  .data nodes
    .enter!.insert \svg:g
      ..
        .attr \class \node
      ..append \svg:g
        ..
          .attr \transform 'scale(0)'
          .transition!
            .duration 1000
            .ease \elastic
            .attr \transform 'scale(1)'
        ..append \svg:path
          .attr \fill \green
          .attr \d arc end-angle: 0
        ..append \svg:circle
          .attr \r -> it.radius
          .style \fill \#e0d498
        ..append \foreignObject
          .attr \x -100px
          .attr \y -100px
          .attr \width  200px
          .attr \height 200px
          .append \xhtml:body
            .attr \id \root-body
            .style \height \100%


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
    ..enter!.insert \svg:g
      ..
        .attr \class \node
      ..append \svg:circle
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
    .attr \transform -> "translate(#{it.x}, #{it.y})"

hash = window.location.pathname.substr 1

client = new WebTorrent!

bytes-to-human = do ->
  units = <[ bytes kB MB GB TB PB ]>
  (bytes) ->
    return \0 unless bytes
    e = Math.floor (Math.log bytes) / Math.log 1024
    ((bytes / Math.pow 1024, e).to-fixed 2)  + ' ' + units[e]

tween-progress = (transition, progress) !->
  transition.attr-tween \d (d) ->
    interpolate = d3.interpolate d.progress-angle, progress * 2 * Math.PI
    (t) ->
      d.progress-angle = interpolate t
      arc end-angle: d.progress-angle

on-torrent = (torrent) !->
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

  torrent.swarm.on \download !->
    svg.select \.node .select \path
      .transition!
        .call tween-progress, torrent.progress

    d3.select \#download-speed .text (bytes-to-human client.download-speed!) + '\/s'

    if torrent.progress is 1
      on-download-complete torrent.files[0]

    #console.log torrent.pieces

  torrent.swarm.on \upload   !->
    d3.select \#upload-speed   .text (bytes-to-human client.upload-speed!) + '\/s'

  d3.select \#preview-button .on \click ->
    alert 'Coming soon!'

  d3.select \#download-button .on \click ->
    unless blob-URL?
      alert 'Something went wrong with the download! Please refresh and try again.'
      return
    document.create-element \a
      ..download = filename
      ..href = blob-URL
      ..click!

  #torrent.files.for-each !->
  #  it.append-to \body


require! './templates/stats.jade'

unless hash.match /\b([0-9a-f]{40})\b/
  require! './templates/upload.jade'

  d3.select \#root-body .html upload!

  new Dropzone \div#upload do
    url: \#
    accept: ->
    addedfile: !->
      d3.select \#root-body .html stats!
      d3.select \#speeds .style \margin-top \32px
      d3.select \#preview .style \display \inline
      d3.select \#filename .text it.name
      d3.select \#filesize .text bytes-to-human it.size
      client.seed it, !->
        window.history.replace-state {}, 'Info Hash', "/#{it.infoHash}"
        on-torrent it

    thumbnail-width: null

    thumbnail: (file, data) !->
      d3.select \#thumbnail
        .style \background-image "url('#data')"

else
  d3.select \#root-body .html stats!

  filename = ''
  blob-URL = null

  on-download-complete = (file) !->
    d3.select \#download-speed .text 0
    d3.select \#buttons
      .style \display \inline

    filename := file.name

    file.get-blob-URL (err, url) !->
      if (err)
        alert err
        return
      blob-URL := url

  client.add hash, on-torrent
