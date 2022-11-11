import AddCollection from 'raw-loader!./../../graphql/mutations/add_collection.graphql'
import DeleteCollection from 'raw-loader!./../../graphql/mutations/delete_collection.graphql'
import GetCollections from 'raw-loader!./../../graphql/queries/get_collections.graphql'
import {post_request} from "./net";
import {
    AddCollectionMutation,
    AddCollectionMutationVariables, DeleteCollectionMutation, DeleteCollectionMutationVariables,
    GetCollectionsQuery
} from "../../graphql/generated";

export function get_collections(): Promise<GetCollectionsQuery> {
    const request = {
        query: GetCollections,
    };
    return post_request(request);
}

export function add_collection(name: string, rootPath: string, watch: boolean): Promise<AddCollectionMutation> {
    const request = {
        query: AddCollection,
        variables: {
            "name": name,
            "rootPath": rootPath,
            "watch": watch,
        }
    };
    return post_request<AddCollectionMutation, AddCollectionMutationVariables>(request);
}

export function delete_collection(collection_id: string): Promise<DeleteCollectionMutation> {
    const request = {
        query: DeleteCollection,
        variables: {
            "collectionId": collection_id,
        }
    };
    return post_request<DeleteCollectionMutation, DeleteCollectionMutationVariables>(request);
}
