# Proyecto Final UM Cloud Devops 2019

La propuesta consiste en :

1. Cloudificar la aplicación [SyncThings](https://syncthing.net/). StateFull: ID, Data.
2. Auth usando [oauth2-proxy](https://github.com/bitly/oauth2_proxy).
3. PeerID loading.

## Cloudificar la aplicación [SyncThings](https://syncthing.net/).

Usé un [StatefulSet](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/master/syncthing.sts.yaml) para permitir la persistencia de los ID y de los datos. En la implementación prdeterminada tanto el archivo config.xml como la carpeta de datos se encuentran en el path /config por lo que definí un volumeClaimTemplates y lo monté en /config. Con esto persistimos el ID del device que se encuentra en config.xml y las carpetas sincronizadas que estan /config/

Definí un [Service](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/master/syncthing.service.yaml) para poder acceder al puerto 8384, predeterminado de la GUI de la aplicación, mapeandolo al 80 y nombrandolo **syncthing**. 

Por último creé un [Ingress](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/master/syncthing.ingress.yaml) para poder accederlo, en donde definí como host a **[syncthing.jcastillo.kube.um.edu.ar](http://syncthing.jcastillo.kube.um.edu.ar)**. También agregué las anotaciones para nginx que realizan las redirecciones para Auth.

  > `nginx.ingress.kubernetes.io/auth-url: "https://$host/oauth2/auth"`
  >
  > `nginx.ingress.kubernetes.io/auth-signin: "https://$host/oauth2/start?rd=$escaped_request_uri"`

## Auth usando [oauth2-proxy](https://github.com/bitly/oauth2_proxy)

Usé un [Deployment](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/master/oauth2-proxy.deployment.yaml) con la imagen container [bitnami/oauth2-proxy](https://hub.docker.com/r/bitnami/oauth2-proxy/) definiendo via args el provider

  > `args:`
  >
  > `--provider=github`
  
  En github creé la OAuth App **syncthing.jcastillo** en donde parametricé
  
  > Authorization callback URL = http://syncthing.jcastillo.kube.um.edu.ar/oauth2
  
  Esto generó un **Client Id** y un **Client Secret** que los agregué a un [Secret](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/master/oauth2-proxy.secret.yaml) que se utiliza en en el Deployment para setear las variables de entorno **OAUTH2_PROXY_CLIENT_ID**, **OAUTH2_PROXY_CLIENT_SECRET** y **OAUTH2_PROXY_COOKIE_SECRET** esta última generada mediante:
  
  > `python -c 'import os,base64; print base64.urlsafe_b64encode(os.urandom(16))'`
  
  Por último creé un [Ingress](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/master/oauth2-proxy.ingress.yaml), en donde definí como host a  **[syncthing.jcastillo.kube.um.edu.ar](http://syncthing.jcastillo.kube.um.edu.ar)** y como path a **/oauth2**.
  
  Ademas mediante anotaciones de nginx, aseguramos el canal mediante tls con los certificados de letsencrypt:
  
  > `certmanager.k8s.io/acme-challenge-type: http01`
  >
  > `certmanager.k8s.io/cluster-issuer: letsencrypt-prod`
  
## PeerID loading

  Mi intento de implementación (sin funcionar) esta en la branch [peerid-loading](https://github.com/jeremiascastillo/umcloud-devops-2019-project/tree/peerid-loading). 
  
  Debido a que la configuración de los devices esta en en el archivo **/config/config.xml** con el formato:
  
  > `<device id="SJS5NQT-GRDZOFR-6YKWREJ-KPSUR45-4BAE3WY-CMAWB6U-XBEAXAL-S4OUDAK" name="syncthing-0" compression="metadata" introducer="false" skipIntroductionRemovals="false" introducedBy="">
  >      <address>dynamic</address>
  >      <paused>false</paused>
  >      <autoAcceptFolders>true</autoAcceptFolders>
  >      <maxSendKbps>0</maxSendKbps>
  >      <maxRecvKbps>0</maxRecvKbps>
  >      <maxRequestKiB>0</maxRequestKiB>
  >  </device>`

  La idea es definir un [ConfigMap](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/peerid-loading/syncthing.cm.yaml) en donde agregar los ID de los devices que quiero que esten sincronizados. 
  
  Para poder revisar si en el config.xml se encontraban los ID devices ya definidos o había que agregarlos, creé un **initContainer** en donde se ejecuta una serie de comandos para parsear el archivo y agregar en caso de ser necesario. Este script es [add-devices.sh](https://github.com/jeremiascastillo/umcloud-devops-2019-project/blob/peerid-loading/add-device.sh) que termine agregando su contenido dentro de la etiqueta **command:** del initContainer. Estos comandos toman de la variable de entorno **DEVICES** que se completa con lo definido en el ConfigMap de los devices IDs.
  
  El problema es que no pude lograr que la secuencia de comandos se ejecutará correctamente y modificará el config.xml de manera correcta.  
