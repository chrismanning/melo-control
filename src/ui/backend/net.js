export function post_request(request, callback) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', "http://localhost:5000/api");
    xhr.onreadystatechange = () => {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            console.debug(xhr.responseText);
            if (callback) {
                callback(JSON.parse(xhr.responseText));
            }
        }
    };
    xhr.send(JSON.stringify(request));
}
