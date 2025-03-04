'use strict';
import * as path from "path";
export const handler = (event, context, callback) => {
    // Extract the request from the CloudFront event that is sent to Lambda@Edge 
    var request = event.Records[0].cf.request;
    // Extract the URI from the request
    var olduri = request.uri;
    // If last element of old uri doesn't contain a .html extension, assume it's a directory and append a '/'
    if (!olduri.match(/\/$/) && path.basename(olduri).match(/^[^\.]+$/)){
        olduri = olduri + '/';
    }
    // Match any '/' that occurs at the end of a URI. Replace it with a default index
    var newuri = olduri.replace(/\/$/, '\/index.html');
    // Log the URI as received by CloudFront and the new URI to be used to fetch from origin
    console.log("Old URI: " + olduri);
    console.log("New URI: " + newuri);
    // Replace the received URI with the URI that includes the index page
    request.uri = newuri;
    // Return to CloudFront
    return callback(null, request);
};