import GetCollectionSources from 'raw-loader!./../../graphql/queries/get_collection_sources.graphql'
import {GraphQLResponse, post_request} from "./net";

export function get_collection_sources(collection_id: string): Promise<GraphQLResponse> {
    const request = {
        query: GetCollectionSources,
        variables: {
            "collectionId": collection_id,
        }
    };
    return post_request(request);
}
