# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Frontend (Vite + Vue)

The app is bundled with [Vite](https://vitejs.dev/) and now ships with Vue 3 out of
the box. The main entrypoint lives in `app/frontend/entrypoints/application.js`
and mounts the component defined in `app/frontend/vue/App.vue` whenever an element
with the id `vue-app` exists on the page.

To render a Vue tree inside a Rails view, add something like the following to your
template:

```haml
#vue-app{ data: { props: { title: 'Custom heading' }.to_json } }
```

Any JSON stored in the `data-props` attribute is passed as props to the root Vue
component, making it easy to hydrate server-provided data.
