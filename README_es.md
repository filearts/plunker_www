# plunker_www

Este es el repositorio que contiene todo el código para ejecutar la parte pública
de http://plnkr.co.

## Instalación

Para iniciar, clone este repositorio e instale las dependencias npm.

```
git clone https://github.com/filearts/plunker_www.git plunker_www
cd plunker_www
npm install
```

 > Podría necesitar hacer el git clone usando la abndera --recursive para obtener
 > los submódulos automáticamente llenados.

A continuación, debe crear los archivos de configuración para los ambientes en los que pretenda
ejecutar Plunker. Normalmente, estos serían `development` y `production`.

Cree `config.development.json` y `config.production.json` con la
siguiente estructura:

```javascript
{
  "host": "hostname.com",
  "url": {
    "www": "http://hostname.com",
    "collab": "http://collab.hostname.com",
    "api": "http://api.hostname.com",
    "embed": "http://embed.hostname.com",
    "run": "http://run.hostname.com",
    "carbonadsH": "You can probably ignore this",
    "carbonadsV": "...and this"
  },
  "port": 8080,
  "oauth": {
    "github": {
      "id": "series_of_random_chars",
      "secret": "longer_series_of_random_chars"
    }
  }
}
```

Si solamente desea cambiar el front-end (este repositorio), podría probablemente remplazar
`hostname.com` con `plnkr.co` para cada url excepto `www`.

Para la configuración `oauth`, asegúrese de configurar una aplicación en github
(en https://github.com/settings/applications) y copiar el `id` y `secret`
para los archivos config.

# Estructura del proyecto

```
 -+ assets - Contenidos
  |-- css - Estilos less / css
  |-- img - Imágenes
  |-+ js 
    |-- apps - Punto de entrada de la página de inicio y el editor
    |-- controllers - MAnejadores de ruta para diferentes 'pages'
    |-- directives - Donde la mayoría de la magia sucede
    |-- panes - Módulos que son cargados automáticamente como paneles en el multi pánel
    |-- services - Código diseñado para ser compartido en toda la app
  |-- snippets - Snippets usados por el editor ace para la expansión de snippets
  |-- vendor - Librerías de terceros
 -+ middleware - Middleware express
 -+ views - Vistas jade para renderizarel markup inicial para las páginas inicio/editor
```
