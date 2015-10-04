require! express

express!
  ..use express.static 'build'
  ..use (req, res) !-> res.send-file 'build/index.html' root: './'
  ..listen (process.env.PORT or 9980)
