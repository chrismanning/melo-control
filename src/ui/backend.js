import * as Collection from "./backend/collection";

export function hello() {
    get_collections()
    return "Hello from JavaScript!"
}

export const get_collections = Collection.get_collections;
