import ReactNative, { FormData } from 'react-native';
class NotificationService {

registerWithNTM(
  deviceToken,
  proto,
  appDomain,
  authToken,
  callback
) {
  console.log('Inside register function');
  var formData = {
    proto: proto,
    token: deviceToken,
    app_domain: appDomain
  };

  const formBody = Object.keys(formData)
    .map(
      key => encodeURIComponent(key) + '=' + encodeURIComponent(formData[key])
    )
    .join('&');

  console.log('Posting form body ', formBody);

  const requestOptions = {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + authToken,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: formBody
  };

  const url = 'https://ntm.iris.comcast.net/v1/subscriber';

  fetch(url, requestOptions)
    .then(response => {
            setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
            return response.json()
    })
    .then(json => {
      if (json !== undefined) {
        console.log('response ', json);
        return json;
      }
    })
    .then(json => {
      if (typeof callback === 'function') {
        callback(json);
      }
    })
    .catch(error => {
      console.error('ERROR: ' + error);
    });
}

subscribe(id, topic, apnTopic, authToken) {
  const requestOptions = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer {authToken}'
    },
    body: JSON.stringify({
      apn_topic: apnTopic
    })
  };

  const url =
    'https://ntm.iris.comcast.net/v1/subscription/subscriber/' +
    id +
    '/topic/' +
    encodeURI(topic);

  fetch(url, requestOptions)
    .then(response => {
      if (response.status == 200 || response.status === 409) {
        return response;
      } else {
        let error = new Error(response.statusText);
        error.response = response;
        throw error;
      }
    })
    .catch(error => {
      console.error('ERROR: ' + error);
    });
}
};

module.exports = new NotificationService();
