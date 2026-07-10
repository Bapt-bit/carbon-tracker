'use strict'

//------------------------------------------------------------------------------
//--- ajaxRequest --------------------------------------------------------------
//------------------------------------------------------------------------------
// Perform an Ajaxs request.
// \param type The type of the request (GET, DELETE, POST, PUT).
// \param url The url of the request.
// \param callback The callback to call when the request success.
// \param data The data associated with the request.

//anti-bot filter
const API_KEY = 'c4380e61512547e5947ab2f8c0792051ea9be478db88f44e43c6e6b4bc1a5931';
function ajaxRequest(type, url, callback, data = null)
{
    let xhr = new XMLHttpRequest();
    if (type == 'GET' && data != null) {
        url += '?' + data;
    }
    xhr.open(type, url);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.setRequestHeader('X-API-Key', API_KEY);

    xhr.onload = () =>
    {
        switch (xhr.status)
        {
            case 200:
            case 201:
                try {
                    callback(JSON.parse(xhr.responseText));
                } catch (e) {
                    console.error('Invalid JSON response:', e);
                    displayErrors(500);
                }
                break;
            default:
                displayErrors(xhr.status);
        }
    };

    xhr.onerror = () => {
        displayErrors(0); // erreur réseau / CORS
    };

    xhr.send(data);
}
//------------------------------------------------------------------------------
//--- displayErrors ------------------------------------------------------------
//------------------------------------------------------------------------------
// Display an error message accordingly to an error code.
// \param errorCode The error code (HTTP status for example).
function displayErrors(errorCode)
{
   let messages = {
    0: 'Erreur réseau, vérifiez votre connexion',
    400: 'Requête incorrecte',
    401: 'Authentifiez vous',
    404: 'Page non trouvée',
    500: 'Erreur interne du serveur',
    503: 'Service indisponible'
};

    // Display error.
    if (messages[errorCode] != undefined)
        alert('Erreur : ' + messages[errorCode]);
}
