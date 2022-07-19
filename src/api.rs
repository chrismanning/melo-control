// #[derive(GraphQLQuery)]
// #[graphql(
// schema_path = "schema.graphql",
// query_path = "src/queries/get_collections.graphql",
// )]
// pub struct GetCollections;
//
// #[derive(GraphQLQuery)]
// #[graphql(
// schema_path = "schema.graphql",
// query_path = "src/queries/get_collection.graphql",
// )]
// pub struct GetCollection;

include!("../generated.rs");
