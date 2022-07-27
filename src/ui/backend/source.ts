import GetCollectionSources from 'raw-loader!./../../graphql/queries/get_collection_sources.graphql'
import {post_request} from "./net";
import {GetCollectionSourcesQuery, GetCollectionSourcesQueryVariables} from "../../graphql/generated";

export function get_collection_sources(collection_id: string): Promise<GetCollectionSourcesQuery> {
    const request = {
        query: GetCollectionSources,
        variables: {
            "collectionId": collection_id,
        }
    };
    return post_request<GetCollectionSourcesQuery, GetCollectionSourcesQueryVariables>(request);
}
