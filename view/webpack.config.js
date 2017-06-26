var webpack = require("webpack");
var path = require('path');
var ExtractTextPlugin = require('extract-text-webpack-plugin'); 
var extractLess = new ExtractTextPlugin({ filename: 'styles.css' });

module.exports = {
    entry: {
        task: path.join(__dirname, '.', 'task.js')
    },
    externals: /(all|rts|lib|out|runmain).js$/,
    resolve: {
        extensions: ['.webpack.js', '.js', '.css', '.less'],
        modules: ['node_modules']
    },
    devtool: 'source-map',
    output: {
        path: path.resolve(__dirname, '../__www/task-view'),
        filename: '[name].js'
    },
    module: {
        noParse: /(all|rts|lib|out|runmain).js$/,
        rules: [ {
            test: /\.html$/,
            exclude: /node_modules/,
            loader: 'file-loader?name=[name].[ext]'
        }, {
            test: /\.css$/,
            loader: ExtractTextPlugin.extract([ 'style-loader', 'css-loader' ])
        }, {
            test: /\.less$/,
            loader: extractLess.extract([ 'css-loader', 'less-loader' ])
        }, {
            test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
            loader: 'url-loader?limit=10000&minetype=application/font-woff'
        }, {
            test: /(all|rts|lib|out|runmain).js$/,
            loader: 'file-loader' 
        }, {
            test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
            loader: 'file-loader' 
        }]
    },
    plugins: [
        extractLess
    ]
};
