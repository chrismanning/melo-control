import GetCollectionSources from '!raw-loader!./../../graphql/queries/get_collection_sources.graphql.graphql'
import {post_request} from "./net";

export function get_collection_sources(collection_id, callback) {
    const request = {
        query: GetCollectionSources,
        variables: {
            "collectionId": collection_id,
        }
    };
    post_request(request, callback);
}
