@isTest global class ClsMockHttpResponseGoogleStorage implements HttpCalloutMock{
 global HTTPResponse respond(HTTPRequest req) {
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"kind":"storage#object","id":"movie-database/document.json/1499855046872299","selfLink":"https://www.googleapis.com/storage/v1/b/movie-database/o/document.json","name":"document.json","bucket":"movie-database","generation":"1499855046872299","metageneration":"2","contentType":"binary/octet-stream","timeCreated":"2017-07-12T10:24:06.839Z","updated":"2017-07-12T10:52:17.553Z","storageClass":"REGIONAL","timeStorageClassUpdated":"2017-07-12T10:24:06.839Z","size":"630","md5Hash":"OCQlXAqft2KWcvQh4f3B9Q==","mediaLink":"https://www.googleapis.com/download/storage/v1/b/movie-database/o/document.json?generation=1499855046872299&alt=media","crc32c":"nG5vPg==","etag":"COuZorrDg9UCEAI="}');
        res.setStatusCode(200);
        return res; 
    }
}