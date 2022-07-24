import AddCollection from '!raw-loader!./../../graphql/mutations/add_collection.graphql'
import DeleteCollection from '!raw-loader!./../../graphql/mutations/delete_collection.graphql'
import GetCollections from '!raw-loader!./../../graphql/queries/get_collections.graphql'
import GetCollection from '!raw-loader!./../../graphql/queries/get_collection.graphql'
import {post_request} from "./net";

export function get_collections(callback) {
    const request = {
        query: GetCollections,
    };
    post_request(request, callback);
}

export function get_collection(collection_id, callback) {
    const request = {
        query: GetCollection,
        variables: {
            "collectionId": collection_id,
        }
    };
    post_request(request, callback);
}

export function add_collection(name, rootPath, watch, callback) {
    const request = {
        query: AddCollection,
        variables: {
            "name": name,
            "rootPath": rootPath,
            "watch": watch,
        }
    };
    post_request(request, callback);
}

export function delete_collection(collection_id, callback) {
    const request = {
        query: DeleteCollection,
        variables: {
            "collectionId": collection_id,
        }
    };
    post_request(request, callback);
}
