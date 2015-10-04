var webpack = require('webpack');

module.exports = {
	entry: './src/index.ls',
	output: {
		path: __dirname + '/build',
		filename: 'index.min.js'
	},
	module: {
		loaders: [
			{ test: /\.ls$/, loader: 'livescript' },
			{ test: /\.jade$/, loader: 'jade' },
			{ test: /\.styl$/, loader: 'style-loader!css-loader!stylus-loader' }
		]
	},
	debug: true,
	devtool: 'source-map',
	plugins: [
		new webpack.optimize.UglifyJsPlugin({
			compress: {
				warnings: false
			},
			sourceMap: true,
			mangle: false
		})
	]
};
