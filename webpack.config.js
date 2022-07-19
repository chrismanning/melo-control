module.exports = {
    entry: {
        backend: {
            import: [
                './src/ui/backend.js',
            ],
            library: {
                type: 'var',
                name: 'exports',
            }
        },
    },
    output: {
        filename: '[name].js',
        path: __dirname + '/dist',
    },
    module: {
        rules: [
            {
                test: /\.m?js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            },
            {
                test: /\/src\/\/(queries|mutations)\/*.graphql/,
                type: 'asset/source',
                use: {
                    loader: 'raw-loader',
                    options: {
                        raw: true
                    }
                }
            }
        ]
    }
};
