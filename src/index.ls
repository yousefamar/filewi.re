require! { 'webtorrent': WebTorrent }

client = new WebTorrent!
hash = \da40fb70e29f1fc659cd21848ff7d431ff48feb8

client.add hash, (torrent) !->
  torrent.files.for-each !->
    it.append-to \body
