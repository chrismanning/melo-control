module.exports = {
    entry: {
        backend: {
            import: [
                './src/ui/backend.ts',
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
                test: /\.ts$/,
                exclude: /node_modules/,
                use: {
                    loader: 'ts-loader'
                }
            }
        ]
    },
    resolve: {
        extensions: ['.ts','.js','.graphql']
    }
};
