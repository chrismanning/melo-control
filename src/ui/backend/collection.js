import GetCollections from '!raw-loader!./../../queries/get_collections.graphql'

export function get_collections(callback) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', "http://localhost:5000/api");
    xhr.onreadystatechange = () => {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            console.log(xhr.responseText);
            if (callback) {
                callback(JSON.parse(xhr.responseText));
            }
        }
    };
    const query = {
        query: GetCollections,
    };
    xhr.send(JSON.stringify(query));
}
