require! { express, 'geoip-lite': geoip }

express!
  ..use express.static '.'

  ..get '*/flag' (req, res) !->
    unless req.query.ip?
      res.write-head 400
      res.end!
      return
    geo = geoip.lookup req.query.ip
    unless geo?
      res.send-file 'res/flags/??.png' root: './'
      return
    res.send-file 'res/flags/' + geo.country.to-lower-case! + '.png' root: './'

  ..use (req, res) !-> res.send-file 'index.html' root: './'
  ..listen (process.env.PORT or 8080)
