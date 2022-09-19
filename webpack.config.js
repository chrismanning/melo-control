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
        diff: {
            import: [
                './src/ui/diff.ts',
            ],
            library: {
                type: 'var',
                name: 'exports',
            }
        }
    },
    output: {
        filename: '[name].js',
        path: __dirname + '/dist',
    },
    module: {
        rules: [
            {
                test: /(?!compiler_depend)\.ts$/,
                exclude: [
                    /compiler_depend\.ts/,
                    /node_modules/,
                    /qsyncable/,
                    /target/,
                    /build/
                ],
                loader: 'ts-loader'
            }
        ]
    },
    resolve: {
        extensions: ['.ts','.js','.graphql']
    }
};
